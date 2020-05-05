'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var React = _interopDefault(require('react'));

function useHook(local) {
    var _a = React.useState(0), num = _a[0], render = _a[1];
    React.useEffect(function () {
        local.onChange.add(function () { return render(num + 1); });
    }, []);
    console.dir("uh....realy?!?!?!?!");
}

exports.useHook = useHook;
