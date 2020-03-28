'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var Dynamic = _interopDefault(require('@ironbay/dynamic'));
var WebSocket = require('universal-websocket-client');

/*! *****************************************************************************
Copyright (c) Microsoft Corporation. All rights reserved.
Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at http://www.apache.org/licenses/LICENSE-2.0

THIS CODE IS PROVIDED ON AN *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
MERCHANTABLITY OR NON-INFRINGEMENT.

See the Apache Version 2.0 License for specific language governing permissions
and limitations under the License.
***************************************************************************** */

function __awaiter(thisArg, _arguments, P, generator) {
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : new P(function (resolve) { resolve(result.value); }).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
}

class Dispatcher {
    constructor() {
        this.callbacks = new Array();
    }
    add(cb) {
        this.callbacks.push(cb);
    }
    trigger(msg, delay = 0) {
        this.callbacks.forEach(cb => cb(msg));
    }
}

class Interceptor {
    constructor() {
        this.before = new Array();
    }
    before_mutation(path, callback) {
        this.before.push({
            path,
            callback
        });
    }
    trigger_before(mut) {
        return __awaiter(this, void 0, void 0, function* () {
            for (let interceptor of this.before) {
                const promises = Interceptor
                    .pattern(mut, interceptor.path)
                    .map((pattern) => __awaiter(this, void 0, void 0, function* () { return yield interceptor.callback(pattern.value, pattern.path, mut); }));
                yield Promise.all(promises);
            }
            return mut;
        });
    }
    static pattern(mut, path) {
        const layers = {};
        Dynamic
            .get_pattern(mut.merge, path)
            .reduce((collect, item) => {
            return Dynamic.put(collect, [item.path, 'merge'], item.value);
        }, layers);
        Dynamic
            .get_pattern(mut.delete, path)
            .reduce((collect, item) => {
            return Dynamic.put(collect, [item.path, 'delete'], item.value);
        }, layers);
        return Object
            .entries(layers)
            .map(([path, obj]) => {
            return {
                path: path.split(','),
                value: {
                    merge: obj.merge || {},
                    delete: obj.delete || {}
                }
            };
        });
    }
}

function mixin(derivedCtor, baseCtors) {
    baseCtors.forEach(baseCtor => {
        Object.getOwnPropertyNames(baseCtor.prototype).forEach(name => {
            Object.defineProperty(derivedCtor.prototype, name, Object.getOwnPropertyDescriptor(baseCtor.prototype, name));
        });
    });
}

class Mutator {
    merge(path, value) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.mutation({
                merge: Dynamic.put({}, path, value),
                delete: {}
            });
        });
    }
    delete(path) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.mutation({
                delete: Dynamic.put({}, path, 1),
                merge: {}
            });
        });
    }
}

class Local {
    constructor() {
        this.onChange = new Dispatcher();
        this.interceptor = new Interceptor();
    }
    mutation(mut) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.interceptor.trigger_before(mut);
            this.mutation_raw(mut);
            this.onChange.trigger(mut);
        });
    }
    query(q) {
        return this.query_raw(q);
    }
    sync(target) {
        return new Sync(this, target);
    }
    query_path(path, opts = {}) {
        return Dynamic.get(this.query(path.length === 0 ? {} : Dynamic.put({}, path, opts)), path);
    }
    query_values(path, opts = {}) {
        return Object.values(this.query_path(path, opts) || {});
    }
    query_keys(path, opts = {}) {
        return Object.keys(this.query_path(path, opts) || {});
    }
}
mixin(Local, [Mutator]);
class Sync {
    constructor(local, target) {
        this.local = local;
        this.target = target;
        target.onChange.add((mut) => __awaiter(this, void 0, void 0, function* () {
            yield this.local.mutation(mut);
        }));
    }
    mutation(mut) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.local.mutation(mut);
            yield this.target.mutation(mut);
        });
    }
}
mixin(Sync, [Mutator]);

class Memory extends Local {
    constructor() {
        super(...arguments);
        this.state = {};
    }
    mutation_raw(mut) {
        Memory.delete(this.state, mut.delete);
        Memory.merge(this.state, mut.merge);
    }
    mutation_reverse(mut) {
        return Memory.merge_reverse(this.state, mut.merge);
    }
    query_raw(query) {
        return Memory.query(this.state, query);
    }
    static query(state, input) {
        const result = {};
        let found = false;
        for (let key of Object.keys(input)) {
            const value = input[key];
            if (value instanceof Object) {
                found = true;
                const existing = state && state[key];
                result[key] = Memory.query(existing, value);
            }
        }
        if (!found)
            return state;
        return result;
    }
    static delete(state, input) {
        for (let key of Object.keys(input)) {
            const value = input[key];
            if (value === 1) {
                delete state[key];
                continue;
            }
            const existing = state[key];
            if (!existing)
                continue;
            Memory.delete(existing, value);
        }
    }
    static merge(state, input) {
        for (let key of Object.keys(input)) {
            const value = input[key];
            if (!(value instanceof Object)) {
                state[key] = value;
                continue;
            }
            if (!state[key])
                state[key] = {};
            const existing = state[key];
            Memory.merge(existing, value);
            continue;
        }
    }
    static merge_reverse(state, input) {
        const result = {
            merge: {},
            delete: {}
        };
        for (let key of Object.keys(input)) {
            const value = input[key];
            const exists = state[key];
            if (!exists) {
                result.delete[key] = 1;
                continue;
            }
            if (!(value instanceof Object)) {
                result.merge[key] = exists;
                continue;
            }
            const child = this.merge_reverse(exists, value);
            result.merge[key] = child.merge;
            result.delete[key] = child.delete;
        }
        return result;
    }
}

class Remote {
    constructor(client) {
        this.onChange = new Dispatcher();
        this.conn = client;
        client.on_cast.add(msg => {
            if (msg.action !== 'riptide.mutation')
                return;
            this.onChange.trigger(msg.body);
        });
    }
    mutation(mut) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.conn.call('riptide.mutation', mut);
        });
    }
    query(q) {
        return __awaiter(this, void 0, void 0, function* () {
            const result = yield this.conn.call('riptide.query', q);
            this.onChange.trigger(result);
            return result.merge;
        });
    }
    query_path(path, opts = {}) {
        return __awaiter(this, void 0, void 0, function* () {
            return Dynamic.get(yield this.query(Dynamic.put({}, path, opts)), path);
        });
    }
    query_values(path, opts = {}) {
        return __awaiter(this, void 0, void 0, function* () {
            return Object.values((yield this.query_path(path, opts)) || {});
        });
    }
    query_keys(path, opts = {}) {
        return __awaiter(this, void 0, void 0, function* () {
            return Object.keys((yield this.query_path(path, opts)) || {});
        });
    }
}
mixin(Remote, [Mutator]);



var index = /*#__PURE__*/Object.freeze({
    __proto__: null,
    Memory: Memory,
    Local: Local,
    Remote: Remote
});

function sleep (time) {
    return new Promise((resolve) => {
        setTimeout(() => resolve(time), time);
    });
}

class Base {
    constructor() {
        this.dispatcher_data = new Dispatcher();
    }
    handle_data(cb) {
        this.dispatcher_data.add(cb);
    }
}
class WS extends Base {
    constructor() {
        super(...arguments);
        this.attempts = -1;
        this.onStatus = new Dispatcher();
    }
    write(data) {
        if (!this.socket || this.socket.readyState !== 1)
            throw 'Socket unready';
        this.socket.send(data);
    }
    connect(url) {
        return __awaiter(this, void 0, void 0, function* () {
            this.attempts++;
            yield sleep(Math.min(this.attempts * 1000, 5 * 1000));
            this.socket = new WebSocket(url);
            this.socket.onopen = () => {
                this.attempts = 0;
                this.onStatus.trigger('ready');
            };
            this.socket.onclose = () => {
                this.cleanup();
                this.connect(url);
            };
            this.socket.onerror = () => {
                // this._cleanup()
                // this._connect()
            };
            this.socket.onmessage = evt => {
                this.dispatcher_data.trigger(evt.data);
            };
        });
    }
    disconnect() {
        if (!this.socket)
            return;
        this.socket.onclose = () => { };
        this.socket.close();
        this.cleanup();
    }
    cleanup() {
        this.onStatus.trigger('disconnected');
        this.socket = undefined;
    }
}

var transport = /*#__PURE__*/Object.freeze({
    __proto__: null,
    Base: Base,
    WS: WS
});

class Json {
    encode(input) {
        return JSON.stringify(input);
    }
    decode(input) {
        const result = JSON.parse(input);
        return result;
    }
}

var format = /*#__PURE__*/Object.freeze({
    __proto__: null,
    Json: Json
});

class Client {
    constructor(transport = null, format = null) {
        this.counter = 0;
        this.on_cast = new Dispatcher();
        this.pending = new Map();
        this.transport = new transport();
        this.transport.handle_data(data => this.handle_data(data));
        this.format = new format();
    }
    call(action, body) {
        return __awaiter(this, void 0, void 0, function* () {
            this.counter++;
            const promise = new Promise((resolve, reject) => {
                this.pending.set(this.counter, { resolve, reject });
            });
            yield this.write({
                key: this.counter,
                action,
                body,
                type: 'call'
            });
            return promise;
        });
    }
    cast(action, body) {
        return __awaiter(this, void 0, void 0, function* () {
            yield this.write({
                action,
                body,
                type: 'cast'
            });
        });
    }
    write(msg) {
        return __awaiter(this, void 0, void 0, function* () {
            const encoded = this.format.encode(msg);
            try {
                this.transport.write(encoded);
            }
            catch (ex) {
                yield sleep(1000);
                return yield this.write(msg);
            }
        });
    }
    handle_data(data) {
        const msg = this.format.decode(data);
        const match = this.pending.get(msg.key);
        switch (msg.type) {
            case 'reply':
                match.resolve(msg.body);
                this.pending.delete(msg.key);
            case 'error':
                match.reject(msg.body);
                this.pending.delete(msg.key);
            default:
                this.on_cast.trigger(msg);
        }
    }
}

function create() {
    return new Client(WS, Json);
}

var index$1 = /*#__PURE__*/Object.freeze({
    __proto__: null,
    Transport: transport,
    Client: Client,
    Format: format,
    create: create
});

const FORWARDS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
const BACKWARDS = FORWARDS.split('').reverse().join('');
function now() {
    return new Date().getTime();
}
function ascending() {
    return ascending_from(now());
}
function descending() {
    return descending_from(now());
}
function descending_from(timestamp) {
    return generate(timestamp, BACKWARDS, BACKWARDS);
}
function descending_uniform(timestamp) {
    return generate(timestamp, BACKWARDS, '0');
}
function ascending_from(timestamp) {
    return generate(timestamp, FORWARDS, FORWARDS);
}
function ascending_uniform(timestamp) {
    return generate(timestamp, FORWARDS, '0');
}
function generate(time, pool, random) {
    const length = pool.length;
    let now = time;
    const result = new Array(20);
    // Time Part
    for (let i = 7; i >= 0; i--) {
        result[i] = pool.charAt(Math.abs(now % length));
        now = Math.floor(now / length);
    }
    // Random Part
    for (let i = 8; i < 20; i++) {
        const r = Math.floor(Math.random() * random.length);
        result[i] = random.charAt(r);
    }
    return result.join('');
}

var uuid = /*#__PURE__*/Object.freeze({
    __proto__: null,
    ascending: ascending,
    descending: descending,
    descending_from: descending_from,
    descending_uniform: descending_uniform,
    ascending_from: ascending_from,
    ascending_uniform: ascending_uniform
});

function create$1() {
}

exports.Connection = index$1;
exports.Store = index;
exports.UUID = uuid;
exports.create = create$1;
