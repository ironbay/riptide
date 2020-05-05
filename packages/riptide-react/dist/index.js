'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

var React = require('react');

function useRiptide(local) {
    const [num, render] = React.useState(0);
    React.useEffect(() => {
        local.onChange.add(() => render(num + 1));
    }, []);
}

exports.useRiptide = useRiptide;
