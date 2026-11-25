// The order report with protoc-gen-go, for comparison: the same orders, the same steps, the same
// bytes out.
//
//	go run . generate 1000000 orders.pb
//	go run . report orders.pb shipped.pb report.pb
package main

import (
	"cmp"
	"fmt"
	"os"
	"slices"
	"strconv"
	"time"

	"google.golang.org/protobuf/proto"

	"example.com/order-report/shop"
)

func main() {
	switch {
	case len(os.Args) == 4 && os.Args[1] == "generate":
		count, err := strconv.Atoi(os.Args[2])
		if err != nil {
			count = 1000000
		}
		generate(count, os.Args[3])
	case len(os.Args) == 5 && os.Args[1] == "report":
		report(os.Args[2], os.Args[3], os.Args[4])
	default:
		fmt.Println("order-report generate <count> <file> | order-report report <orders> <shipped> <report>")
	}
}

func generate(count int, path string) {
	orders := make([]*shop.Order, count)
	for index := range orders {
		orders[index] = sampleOrder(int32(index + 1))
	}
	write(path, must(proto.Marshal(&shop.OrderLog{Orders: orders})))
	fmt.Printf("wrote %d orders to %s\n", count, path)
}

func report(input string, shippedPath string, reportPath string) {
	bytes := must(os.ReadFile(input))

	start := time.Now()
	var log shop.OrderLog
	if err := proto.Unmarshal(bytes, &log); err != nil {
		panic(err)
	}
	orders := log.Orders
	lap("decode", start)

	start = time.Now()
	shipped := shipWithCoupons(orders)
	lap("ship", start)

	start = time.Now()
	totals := totalsByCustomer(shipped)
	lap("total", start)

	start = time.Now()
	encoded := must(proto.Marshal(&shop.OrderLog{Orders: shipped}))
	lap("encode", start)
	write(shippedPath, encoded)

	top := topCustomers(totals)
	var revenue int64
	for _, total := range totals {
		revenue += total.RevenueCents
	}
	summary := &shop.Report{OrdersRead: int32(len(orders)), OrdersShipped: int32(len(shipped)), RevenueCents: revenue, TopCustomers: top}
	write(reportPath, must(proto.Marshal(summary)))
	fmt.Printf("%d orders, %d shipped, %d customers\n", len(orders), len(shipped), len(totals))
	for _, customer := range top {
		fmt.Printf("  %s  $%d.%02d in %d orders\n", customer.Customer, customer.RevenueCents/100, customer.RevenueCents%100, customer.Orders)
	}
}

func shipWithCoupons(orders []*shop.Order) []*shop.Order {
	shipped := make([]*shop.Order, 0, len(orders))
	for _, order := range orders {
		if order.Status != shop.Status_STATUS_SHIPPED {
			continue
		}
		if order.Coupon != nil && *order.Coupon == "TENOFF" {
			items := make([]*shop.LineItem, len(order.Items))
			for index, item := range order.Items {
				items[index] = &shop.LineItem{Sku: item.Sku, Quantity: item.Quantity, UnitPriceCents: item.UnitPriceCents * 9 / 10}
			}
			order = &shop.Order{Id: order.Id, Customer: order.Customer, Status: order.Status, Items: items}
		}
		shipped = append(shipped, order)
	}
	return shipped
}

func totalsByCustomer(orders []*shop.Order) map[string]*shop.CustomerTotal {
	totals := map[string]*shop.CustomerTotal{}
	for _, order := range orders {
		total, found := totals[order.Customer]
		if !found {
			total = &shop.CustomerTotal{Customer: order.Customer}
			totals[order.Customer] = total
		}
		for _, item := range order.Items {
			total.RevenueCents += int64(item.Quantity) * int64(item.UnitPriceCents)
		}
		total.Orders++
	}
	return totals
}

func topCustomers(totals map[string]*shop.CustomerTotal) []*shop.CustomerTotal {
	all := make([]*shop.CustomerTotal, 0, len(totals))
	for _, total := range totals {
		all = append(all, total)
	}
	slices.SortFunc(all, func(a, b *shop.CustomerTotal) int {
		return cmp.Or(cmp.Compare(b.RevenueCents, a.RevenueCents), cmp.Compare(a.Customer, b.Customer))
	})
	return all[:min(5, len(all))]
}

func sampleOrder(n int32) *shop.Order {
	status := shop.Status_STATUS_SHIPPED
	switch n % 10 {
	case 0:
		status = shop.Status_STATUS_CANCELLED
	case 1, 2:
		status = shop.Status_STATUS_PLACED
	}
	items := make([]*shop.LineItem, 1+n%4)
	for index := range items {
		line := int32(index + 1)
		items[index] = &shop.LineItem{
			Sku:            "SKU-" + strconv.Itoa(int((n+line*13)%500)),
			Quantity:       1 + (n+line)%5,
			UnitPriceCents: 199 + (n*31+line*17)%9800,
		}
	}
	var coupon *string
	if n%7 == 0 {
		coupon = proto.String("TENOFF")
	} else if n%11 == 0 {
		coupon = proto.String("FREESHIP")
	}
	return &shop.Order{Id: n, Customer: "customer-" + strconv.Itoa(int((n*7)%5000)), Status: status, Items: items, Coupon: coupon}
}

func lap(label string, start time.Time) {
	fmt.Printf("%s  %d ms\n", label, time.Since(start).Milliseconds())
}

func write(path string, data []byte) {
	if err := os.WriteFile(path, data, 0o644); err != nil {
		panic(err)
	}
}

func must[T any](value T, err error) T {
	if err != nil {
		panic(err)
	}
	return value
}
