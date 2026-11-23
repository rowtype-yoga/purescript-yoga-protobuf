/*eslint-disable block-scoped-var, id-length, no-control-regex, no-magic-numbers, no-prototype-builtins, no-redeclare, no-shadow, no-var, sort-vars*/
import * as $protobuf from "protobufjs/minimal";

const $Reader = $protobuf.Reader, $Writer = $protobuf.Writer, $util = $protobuf.util;

const $root = $protobuf.roots["default"] || ($protobuf.roots["default"] = {});

export const bench = $root.bench = (() => {

    const bench = {};

    bench.Inner = (function() {

        function Inner(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        Inner.prototype.a = 0;
        Inner.prototype.b = "";

        Inner.create = function create(properties) {
            return new Inner(properties);
        };

        Inner.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.a != null && Object.hasOwnProperty.call(message, "a"))
                writer.uint32(8).int32(message.a);
            if (message.b != null && Object.hasOwnProperty.call(message, "b"))
                writer.uint32(18).string(message.b);
            return writer;
        };

        Inner.decode = function decode(reader, length, error) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.bench.Inner();
            while (reader.pos < end) {
                let tag = reader.uint32();
                if (tag === error)
                    break;
                switch (tag >>> 3) {
                case 1: {
                        message.a = reader.int32();
                        break;
                    }
                case 2: {
                        message.b = reader.string();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        Inner.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/bench.Inner";
        };

        return Inner;
    })();

    bench.Msg = (function() {

        function Msg(properties) {
            this.nums = [];
            this.tags = {};
            this.labels = [];
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        Msg.prototype.id = 0;
        Msg.prototype.big = $util.Long ? $util.Long.fromBits(0,0,false) : 0;
        Msg.prototype.name = "";
        Msg.prototype.nums = $util.emptyArray;
        Msg.prototype.inner = null;
        Msg.prototype.tags = $util.emptyObject;
        Msg.prototype.score = 0;
        Msg.prototype.ok = false;
        Msg.prototype.labels = $util.emptyArray;

        Msg.create = function create(properties) {
            return new Msg(properties);
        };

        Msg.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.id != null && Object.hasOwnProperty.call(message, "id"))
                writer.uint32(8).int32(message.id);
            if (message.big != null && Object.hasOwnProperty.call(message, "big"))
                writer.uint32(16).int64(message.big);
            if (message.name != null && Object.hasOwnProperty.call(message, "name"))
                writer.uint32(26).string(message.name);
            if (message.nums != null && message.nums.length) {
                writer.uint32(34).fork();
                for (let i = 0; i < message.nums.length; ++i)
                    writer.int32(message.nums[i]);
                writer.ldelim();
            }
            if (message.inner != null && Object.hasOwnProperty.call(message, "inner"))
                $root.bench.Inner.encode(message.inner, writer.uint32(42).fork()).ldelim();
            if (message.tags != null && Object.hasOwnProperty.call(message, "tags"))
                for (let keys = Object.keys(message.tags), i = 0; i < keys.length; ++i)
                    writer.uint32(50).fork().uint32(10).string(keys[i]).uint32(16).int32(message.tags[keys[i]]).ldelim();
            if (message.score != null && Object.hasOwnProperty.call(message, "score"))
                writer.uint32(57).double(message.score);
            if (message.ok != null && Object.hasOwnProperty.call(message, "ok"))
                writer.uint32(64).bool(message.ok);
            if (message.labels != null && message.labels.length)
                for (let i = 0; i < message.labels.length; ++i)
                    writer.uint32(74).string(message.labels[i]);
            return writer;
        };

        Msg.decode = function decode(reader, length, error) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.bench.Msg(), key, value;
            while (reader.pos < end) {
                let tag = reader.uint32();
                if (tag === error)
                    break;
                switch (tag >>> 3) {
                case 1: {
                        message.id = reader.int32();
                        break;
                    }
                case 2: {
                        message.big = reader.int64();
                        break;
                    }
                case 3: {
                        message.name = reader.string();
                        break;
                    }
                case 4: {
                        if (!(message.nums && message.nums.length))
                            message.nums = [];
                        if ((tag & 7) === 2) {
                            let end2 = reader.uint32() + reader.pos;
                            while (reader.pos < end2)
                                message.nums.push(reader.int32());
                        } else
                            message.nums.push(reader.int32());
                        break;
                    }
                case 5: {
                        message.inner = $root.bench.Inner.decode(reader, reader.uint32());
                        break;
                    }
                case 6: {
                        if (message.tags === $util.emptyObject)
                            message.tags = {};
                        let end2 = reader.uint32() + reader.pos;
                        key = "";
                        value = 0;
                        while (reader.pos < end2) {
                            let tag2 = reader.uint32();
                            switch (tag2 >>> 3) {
                            case 1:
                                key = reader.string();
                                break;
                            case 2:
                                value = reader.int32();
                                break;
                            default:
                                reader.skipType(tag2 & 7);
                                break;
                            }
                        }
                        message.tags[key] = value;
                        break;
                    }
                case 7: {
                        message.score = reader.double();
                        break;
                    }
                case 8: {
                        message.ok = reader.bool();
                        break;
                    }
                case 9: {
                        if (!(message.labels && message.labels.length))
                            message.labels = [];
                        message.labels.push(reader.string());
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        Msg.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/bench.Msg";
        };

        return Msg;
    })();

    bench.RepeatedNested = (function() {

        function RepeatedNested(properties) {
            this.items = [];
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        RepeatedNested.prototype.items = $util.emptyArray;

        RepeatedNested.create = function create(properties) {
            return new RepeatedNested(properties);
        };

        RepeatedNested.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.items != null && message.items.length)
                for (let i = 0; i < message.items.length; ++i)
                    $root.bench.Inner.encode(message.items[i], writer.uint32(10).fork()).ldelim();
            return writer;
        };

        RepeatedNested.decode = function decode(reader, length, error) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.bench.RepeatedNested();
            while (reader.pos < end) {
                let tag = reader.uint32();
                if (tag === error)
                    break;
                switch (tag >>> 3) {
                case 1: {
                        if (!(message.items && message.items.length))
                            message.items = [];
                        message.items.push($root.bench.Inner.decode(reader, reader.uint32()));
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        RepeatedNested.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/bench.RepeatedNested";
        };

        return RepeatedNested;
    })();

    bench.Wide = (function() {

        function Wide(properties) {
            if (properties)
                for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                    if (properties[keys[i]] != null)
                        this[keys[i]] = properties[keys[i]];
        }

        Wide.prototype.f1 = 0;
        Wide.prototype.f2 = "";
        Wide.prototype.f3 = 0;
        Wide.prototype.f4 = $util.Long ? $util.Long.fromBits(0,0,false) : 0;
        Wide.prototype.f5 = false;
        Wide.prototype.f6 = 0;
        Wide.prototype.f7 = "";
        Wide.prototype.f8 = 0;
        Wide.prototype.f9 = $util.Long ? $util.Long.fromBits(0,0,false) : 0;
        Wide.prototype.f10 = false;
        Wide.prototype.f11 = 0;
        Wide.prototype.f12 = "";
        Wide.prototype.f13 = 0;
        Wide.prototype.f14 = $util.Long ? $util.Long.fromBits(0,0,false) : 0;
        Wide.prototype.f15 = false;
        Wide.prototype.f16 = 0;
        Wide.prototype.f17 = "";
        Wide.prototype.f18 = 0;
        Wide.prototype.f19 = $util.Long ? $util.Long.fromBits(0,0,false) : 0;
        Wide.prototype.f20 = false;
        Wide.prototype.f21 = 0;
        Wide.prototype.f22 = "";
        Wide.prototype.f23 = 0;
        Wide.prototype.f24 = $util.Long ? $util.Long.fromBits(0,0,false) : 0;
        Wide.prototype.f25 = false;
        Wide.prototype.f26 = 0;
        Wide.prototype.f27 = "";
        Wide.prototype.f28 = 0;
        Wide.prototype.f29 = $util.Long ? $util.Long.fromBits(0,0,false) : 0;
        Wide.prototype.f30 = false;
        Wide.prototype.f31 = 0;
        Wide.prototype.f32 = "";
        Wide.prototype.f33 = 0;
        Wide.prototype.f34 = $util.Long ? $util.Long.fromBits(0,0,false) : 0;
        Wide.prototype.f35 = false;
        Wide.prototype.f36 = 0;
        Wide.prototype.f37 = "";
        Wide.prototype.f38 = 0;
        Wide.prototype.f39 = $util.Long ? $util.Long.fromBits(0,0,false) : 0;
        Wide.prototype.f40 = false;
        Wide.prototype.f41 = 0;
        Wide.prototype.f42 = "";
        Wide.prototype.f43 = 0;
        Wide.prototype.f44 = $util.Long ? $util.Long.fromBits(0,0,false) : 0;
        Wide.prototype.f45 = false;
        Wide.prototype.f46 = 0;
        Wide.prototype.f47 = "";
        Wide.prototype.f48 = 0;
        Wide.prototype.f49 = $util.Long ? $util.Long.fromBits(0,0,false) : 0;
        Wide.prototype.f50 = false;

        Wide.create = function create(properties) {
            return new Wide(properties);
        };

        Wide.encode = function encode(message, writer) {
            if (!writer)
                writer = $Writer.create();
            if (message.f1 != null && Object.hasOwnProperty.call(message, "f1"))
                writer.uint32(8).int32(message.f1);
            if (message.f2 != null && Object.hasOwnProperty.call(message, "f2"))
                writer.uint32(18).string(message.f2);
            if (message.f3 != null && Object.hasOwnProperty.call(message, "f3"))
                writer.uint32(25).double(message.f3);
            if (message.f4 != null && Object.hasOwnProperty.call(message, "f4"))
                writer.uint32(32).int64(message.f4);
            if (message.f5 != null && Object.hasOwnProperty.call(message, "f5"))
                writer.uint32(40).bool(message.f5);
            if (message.f6 != null && Object.hasOwnProperty.call(message, "f6"))
                writer.uint32(48).int32(message.f6);
            if (message.f7 != null && Object.hasOwnProperty.call(message, "f7"))
                writer.uint32(58).string(message.f7);
            if (message.f8 != null && Object.hasOwnProperty.call(message, "f8"))
                writer.uint32(65).double(message.f8);
            if (message.f9 != null && Object.hasOwnProperty.call(message, "f9"))
                writer.uint32(72).int64(message.f9);
            if (message.f10 != null && Object.hasOwnProperty.call(message, "f10"))
                writer.uint32(80).bool(message.f10);
            if (message.f11 != null && Object.hasOwnProperty.call(message, "f11"))
                writer.uint32(88).int32(message.f11);
            if (message.f12 != null && Object.hasOwnProperty.call(message, "f12"))
                writer.uint32(98).string(message.f12);
            if (message.f13 != null && Object.hasOwnProperty.call(message, "f13"))
                writer.uint32(105).double(message.f13);
            if (message.f14 != null && Object.hasOwnProperty.call(message, "f14"))
                writer.uint32(112).int64(message.f14);
            if (message.f15 != null && Object.hasOwnProperty.call(message, "f15"))
                writer.uint32(120).bool(message.f15);
            if (message.f16 != null && Object.hasOwnProperty.call(message, "f16"))
                writer.uint32(128).int32(message.f16);
            if (message.f17 != null && Object.hasOwnProperty.call(message, "f17"))
                writer.uint32(138).string(message.f17);
            if (message.f18 != null && Object.hasOwnProperty.call(message, "f18"))
                writer.uint32(145).double(message.f18);
            if (message.f19 != null && Object.hasOwnProperty.call(message, "f19"))
                writer.uint32(152).int64(message.f19);
            if (message.f20 != null && Object.hasOwnProperty.call(message, "f20"))
                writer.uint32(160).bool(message.f20);
            if (message.f21 != null && Object.hasOwnProperty.call(message, "f21"))
                writer.uint32(168).int32(message.f21);
            if (message.f22 != null && Object.hasOwnProperty.call(message, "f22"))
                writer.uint32(178).string(message.f22);
            if (message.f23 != null && Object.hasOwnProperty.call(message, "f23"))
                writer.uint32(185).double(message.f23);
            if (message.f24 != null && Object.hasOwnProperty.call(message, "f24"))
                writer.uint32(192).int64(message.f24);
            if (message.f25 != null && Object.hasOwnProperty.call(message, "f25"))
                writer.uint32(200).bool(message.f25);
            if (message.f26 != null && Object.hasOwnProperty.call(message, "f26"))
                writer.uint32(208).int32(message.f26);
            if (message.f27 != null && Object.hasOwnProperty.call(message, "f27"))
                writer.uint32(218).string(message.f27);
            if (message.f28 != null && Object.hasOwnProperty.call(message, "f28"))
                writer.uint32(225).double(message.f28);
            if (message.f29 != null && Object.hasOwnProperty.call(message, "f29"))
                writer.uint32(232).int64(message.f29);
            if (message.f30 != null && Object.hasOwnProperty.call(message, "f30"))
                writer.uint32(240).bool(message.f30);
            if (message.f31 != null && Object.hasOwnProperty.call(message, "f31"))
                writer.uint32(248).int32(message.f31);
            if (message.f32 != null && Object.hasOwnProperty.call(message, "f32"))
                writer.uint32(258).string(message.f32);
            if (message.f33 != null && Object.hasOwnProperty.call(message, "f33"))
                writer.uint32(265).double(message.f33);
            if (message.f34 != null && Object.hasOwnProperty.call(message, "f34"))
                writer.uint32(272).int64(message.f34);
            if (message.f35 != null && Object.hasOwnProperty.call(message, "f35"))
                writer.uint32(280).bool(message.f35);
            if (message.f36 != null && Object.hasOwnProperty.call(message, "f36"))
                writer.uint32(288).int32(message.f36);
            if (message.f37 != null && Object.hasOwnProperty.call(message, "f37"))
                writer.uint32(298).string(message.f37);
            if (message.f38 != null && Object.hasOwnProperty.call(message, "f38"))
                writer.uint32(305).double(message.f38);
            if (message.f39 != null && Object.hasOwnProperty.call(message, "f39"))
                writer.uint32(312).int64(message.f39);
            if (message.f40 != null && Object.hasOwnProperty.call(message, "f40"))
                writer.uint32(320).bool(message.f40);
            if (message.f41 != null && Object.hasOwnProperty.call(message, "f41"))
                writer.uint32(328).int32(message.f41);
            if (message.f42 != null && Object.hasOwnProperty.call(message, "f42"))
                writer.uint32(338).string(message.f42);
            if (message.f43 != null && Object.hasOwnProperty.call(message, "f43"))
                writer.uint32(345).double(message.f43);
            if (message.f44 != null && Object.hasOwnProperty.call(message, "f44"))
                writer.uint32(352).int64(message.f44);
            if (message.f45 != null && Object.hasOwnProperty.call(message, "f45"))
                writer.uint32(360).bool(message.f45);
            if (message.f46 != null && Object.hasOwnProperty.call(message, "f46"))
                writer.uint32(368).int32(message.f46);
            if (message.f47 != null && Object.hasOwnProperty.call(message, "f47"))
                writer.uint32(378).string(message.f47);
            if (message.f48 != null && Object.hasOwnProperty.call(message, "f48"))
                writer.uint32(385).double(message.f48);
            if (message.f49 != null && Object.hasOwnProperty.call(message, "f49"))
                writer.uint32(392).int64(message.f49);
            if (message.f50 != null && Object.hasOwnProperty.call(message, "f50"))
                writer.uint32(400).bool(message.f50);
            return writer;
        };

        Wide.decode = function decode(reader, length, error) {
            if (!(reader instanceof $Reader))
                reader = $Reader.create(reader);
            let end = length === undefined ? reader.len : reader.pos + length, message = new $root.bench.Wide();
            while (reader.pos < end) {
                let tag = reader.uint32();
                if (tag === error)
                    break;
                switch (tag >>> 3) {
                case 1: {
                        message.f1 = reader.int32();
                        break;
                    }
                case 2: {
                        message.f2 = reader.string();
                        break;
                    }
                case 3: {
                        message.f3 = reader.double();
                        break;
                    }
                case 4: {
                        message.f4 = reader.int64();
                        break;
                    }
                case 5: {
                        message.f5 = reader.bool();
                        break;
                    }
                case 6: {
                        message.f6 = reader.int32();
                        break;
                    }
                case 7: {
                        message.f7 = reader.string();
                        break;
                    }
                case 8: {
                        message.f8 = reader.double();
                        break;
                    }
                case 9: {
                        message.f9 = reader.int64();
                        break;
                    }
                case 10: {
                        message.f10 = reader.bool();
                        break;
                    }
                case 11: {
                        message.f11 = reader.int32();
                        break;
                    }
                case 12: {
                        message.f12 = reader.string();
                        break;
                    }
                case 13: {
                        message.f13 = reader.double();
                        break;
                    }
                case 14: {
                        message.f14 = reader.int64();
                        break;
                    }
                case 15: {
                        message.f15 = reader.bool();
                        break;
                    }
                case 16: {
                        message.f16 = reader.int32();
                        break;
                    }
                case 17: {
                        message.f17 = reader.string();
                        break;
                    }
                case 18: {
                        message.f18 = reader.double();
                        break;
                    }
                case 19: {
                        message.f19 = reader.int64();
                        break;
                    }
                case 20: {
                        message.f20 = reader.bool();
                        break;
                    }
                case 21: {
                        message.f21 = reader.int32();
                        break;
                    }
                case 22: {
                        message.f22 = reader.string();
                        break;
                    }
                case 23: {
                        message.f23 = reader.double();
                        break;
                    }
                case 24: {
                        message.f24 = reader.int64();
                        break;
                    }
                case 25: {
                        message.f25 = reader.bool();
                        break;
                    }
                case 26: {
                        message.f26 = reader.int32();
                        break;
                    }
                case 27: {
                        message.f27 = reader.string();
                        break;
                    }
                case 28: {
                        message.f28 = reader.double();
                        break;
                    }
                case 29: {
                        message.f29 = reader.int64();
                        break;
                    }
                case 30: {
                        message.f30 = reader.bool();
                        break;
                    }
                case 31: {
                        message.f31 = reader.int32();
                        break;
                    }
                case 32: {
                        message.f32 = reader.string();
                        break;
                    }
                case 33: {
                        message.f33 = reader.double();
                        break;
                    }
                case 34: {
                        message.f34 = reader.int64();
                        break;
                    }
                case 35: {
                        message.f35 = reader.bool();
                        break;
                    }
                case 36: {
                        message.f36 = reader.int32();
                        break;
                    }
                case 37: {
                        message.f37 = reader.string();
                        break;
                    }
                case 38: {
                        message.f38 = reader.double();
                        break;
                    }
                case 39: {
                        message.f39 = reader.int64();
                        break;
                    }
                case 40: {
                        message.f40 = reader.bool();
                        break;
                    }
                case 41: {
                        message.f41 = reader.int32();
                        break;
                    }
                case 42: {
                        message.f42 = reader.string();
                        break;
                    }
                case 43: {
                        message.f43 = reader.double();
                        break;
                    }
                case 44: {
                        message.f44 = reader.int64();
                        break;
                    }
                case 45: {
                        message.f45 = reader.bool();
                        break;
                    }
                case 46: {
                        message.f46 = reader.int32();
                        break;
                    }
                case 47: {
                        message.f47 = reader.string();
                        break;
                    }
                case 48: {
                        message.f48 = reader.double();
                        break;
                    }
                case 49: {
                        message.f49 = reader.int64();
                        break;
                    }
                case 50: {
                        message.f50 = reader.bool();
                        break;
                    }
                default:
                    reader.skipType(tag & 7);
                    break;
                }
            }
            return message;
        };

        Wide.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
            if (typeUrlPrefix === undefined) {
                typeUrlPrefix = "type.googleapis.com";
            }
            return typeUrlPrefix + "/bench.Wide";
        };

        return Wide;
    })();

    return bench;
})();

export { $root as default };
