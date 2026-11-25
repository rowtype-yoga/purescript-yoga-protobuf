-- | A shop's day of orders as one protocol buffer file: read it, ship what's shipped with its
-- | coupons applied, total up every customer, and write the shipped orders and a report back.
-- |
-- |   order-report generate 1000000 orders.pb
-- |   order-report report orders.pb shipped.pb report.pb
module Main where

import Prelude

import BinaryFile (readBytes, writeChunks)
import Data.Array as Array
import Data.DateTime.Instant (diff)
import Data.Either (Either, either)
import Data.Foldable (foldl, for_, sum)
import Data.Int (round)
import Data.Int as Int
import Data.Int64 (Int64)
import Data.Int64 as Int64
import Data.Map (Map)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (un)
import Data.Ord.Down (Down(..))
import Data.String as String
import Data.Time.Duration (Milliseconds(..))
import Data.Tuple.Nested ((/\))
import Effect (Effect)
import Effect.Console (log)
import Effect.Exception (throw)
import Effect.Now (now)
import Effect.Ref as Ref
import Go.OS (Arg(..), args)
import Proto.Shop (CustomerTotal, LineItem, Order, Report, Status(..), decodeOrderLog, encodeOrderLog, encodeReport)
import Yoga.Protobuf.Bytes (Bytes)

main :: Effect Unit
main = do
  arguments <- args <#> map (un Arg)
  case arguments of
    [ "generate", count, path ] -> generate (Int.fromString count # fromMaybe 1000000) path
    [ "report", input, shippedPath, reportPath ] -> report input shippedPath reportPath
    _ -> log "order-report generate <count> <file> | order-report report <orders> <shipped> <report>"

generate :: Int -> String -> Effect Unit
generate count path = do
  writeChunks path (Array.range 1 count <#> sampleOrder # inChunks)
  log ("wrote " <> show count <> " orders to " <> path)

report :: String -> String -> String -> Effect Unit
report input shippedPath reportPath = do
  bytes <- readBytes input
  { orders } <- timed "decode" (\_ -> decodeOrderLog bytes) >>= orThrow
  shipped <- timed "ship" \_ -> shipWithCoupons orders
  totals <- timed "total" \_ -> totalsByCustomer shipped
  encoded <- timed "encode" \_ -> inChunks shipped
  writeChunks shippedPath encoded
  writeChunks reportPath [ encodeReport (summary orders shipped totals) ]
  printSummary orders shipped totals

shipWithCoupons :: Array Order -> Array Order
shipWithCoupons orders = orders # Array.filter (_.status >>> eq Shipped) <#> applyCoupon
  where
  applyCoupon order = case order.coupon of
    Just "TENOFF" -> order { items = order.items <#> tenPercentOff, coupon = Nothing }
    _ -> order
  tenPercentOff item = item { unitPriceCents = item.unitPriceCents * 9 / 10 }

totalsByCustomer :: Array Order -> Map String CustomerTotal
totalsByCustomer = foldl addOrder Map.empty
  where
  addOrder totals order = Map.insertWith combine order.customer (totalOf order) totals
  totalOf order = { customer: order.customer, revenueCents: sum (order.items <#> lineTotal), orders: 1 }
  combine earlier later = earlier { revenueCents = earlier.revenueCents + later.revenueCents, orders = earlier.orders + later.orders }

lineTotal :: LineItem -> Int64
lineTotal item = Int64.fromInt item.quantity * Int64.fromInt item.unitPriceCents

summary :: Array Order -> Array Order -> Map String CustomerTotal -> Report
summary orders shipped totals =
  { ordersRead: Array.length orders
  , ordersShipped: Array.length shipped
  , revenueCents: sum (Map.values totals <#> _.revenueCents)
  , topCustomers: topCustomers totals
  }

topCustomers :: Map String CustomerTotal -> Array CustomerTotal
topCustomers totals = Map.values totals # Array.fromFoldable # Array.sortWith biggestFirst # Array.take 5
  where
  biggestFirst customer = Down customer.revenueCents /\ customer.customer

printSummary :: Array Order -> Array Order -> Map String CustomerTotal -> Effect Unit
printSummary orders shipped totals = do
  log (show (Array.length orders) <> " orders, " <> show (Array.length shipped) <> " shipped, " <> show (Map.size totals) <> " customers")
  for_ (topCustomers totals) \customer ->
    log ("  " <> customer.customer <> "  " <> dollars customer.revenueCents <> " in " <> show customer.orders <> " orders")

-- | Order number `n` of a made-up day: 5,000 customers, 500 products, one to four lines each.
sampleOrder :: Int -> Order
sampleOrder n =
  { id: n
  , customer: "customer-" <> show ((n * 7) `mod` 5000)
  , status: statusOf (n `mod` 10)
  , items: Array.range 1 (1 + n `mod` 4) <#> lineItem
  , coupon: couponOf n
  }
  where
  statusOf = case _ of
    0 -> Cancelled
    1 -> Placed
    2 -> Placed
    _ -> Shipped
  lineItem line =
    { sku: "SKU-" <> show ((n + line * 13) `mod` 500)
    , quantity: 1 + (n + line) `mod` 5
    , unitPriceCents: 199 + (n * 31 + line * 17) `mod` 9800
    }
  couponOf number
    | number `mod` 7 == 0 = Just "TENOFF"
    | number `mod` 11 == 0 = Just "FREESHIP"
    | otherwise = Nothing

-- | Order logs of 500 orders each, one after the other, are one order log with all of them. Small
-- | messages keep the writer in a buffer that fits.
inChunks :: Array Order -> Array Bytes
inChunks orders = Array.range 0 ((Array.length orders - 1) / chunkSize) <#> \chunk ->
  encodeOrderLog { orders: Array.slice (chunk * chunkSize) ((chunk + 1) * chunkSize) orders }
  where
  chunkSize = 500

-- | Runs the work between two looks at the clock. Putting the result in a `Ref` makes sure it's
-- | computed before the second look.
timed :: forall a. String -> (Unit -> a) -> Effect a
timed label work = do
  start <- now
  result <- Ref.new (work unit) >>= Ref.read
  end <- now
  log (label <> "  " <> show (round (un Milliseconds (diff end start))) <> " ms")
  pure result

orThrow :: forall error a. Show error => Either error a -> Effect a
orThrow = either (show >>> throw) pure

dollars :: Int64 -> String
dollars cents = "$" <> whole <> "." <> fraction
  where
  digits = Int64.toString cents
  { before: whole, after: fraction } = String.splitAt (String.length digits - 2) digits
