/*
* react-native-audio - index.android.js
* Copyright(c) 2015 xeodou <xeodou@gmail.com>
* MIT Licensed
*/

var { requireNativeComponent, PropTypes } = require('react-native');

var iface = {
  name: 'ReactAudio',
  propTypes: {
    url: PropTypes.string
  },
};

module.exports = requireNativeComponent('RCTAudio', iface);
