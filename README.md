### React-Native-Player

> Media Player for React-Native

*Only Android support now.*

#### Integrate

##### Android

* Install via npm
`npm i react-native-player --save-dev`

* Add dependency to `android/settings.gradle`
```
...
include ':react-native-player'
project(':react-native-player').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-player/android/player')
```

* Add `android/app/build.gradle`
```
...
dependencies {
    ...
    compile project(':react-native-player')
}
```
* Register module in `MainActivity.java`
```
import com.xeodou.rctplayer.*;  // <--- import

@Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mReactRootView = new ReactRootView(this);

        mReactInstanceManager = ReactInstanceManager.builder()
                .setApplication(getApplication())
                .setBundleAssetName("index.android.bundle")
                .setJSMainModuleName("index.android")
                .addPackage(new ReactPlayerManager())  // <------- here
                .addPackage(new MainReactPackage())
                .setUseDeveloperSupport(BuildConfig.DEBUG)
                .setInitialLifecycleState(LifecycleState.RESUMED)
                .build();

        mReactRootView.startReactApplication(mReactInstanceManager, "doubanbook", null);

        setContentView(mReactRootView);
    }
```

#### Usage
```
var RCTAudio = require('react-native-player');


var doubanbook = React.createClass({

  mixins: [Subscribable.Mixin],

  componentWillMount: function() {
      this.addListenerOn(RCTDeviceEventEmitter,
                       'error',
                       this.onError);
      this.addListenerOn(RCTDeviceEventEmitter,
                       'end',
                       this.onEnd);
      this.addListenerOn(RCTDeviceEventEmitter,
                       'ready',
                       this.onReady);
  },

  componentDidMount: function() {

  },

  onError: function(err) {
    console.log(err)
  },

  onEnd: function() {
    console.log("end")
  },

  onReady: function() {
    console.log("onReady")
  },

  start: function() {
    RCTAudio.start()
  },

  pause: function() {
    RCTAudio.pause()
  },

  stop: function() {
    RCTAudio.stop()
  },

  buttonClicked: function() {
    RCTAudio.prepare("https://api.soundcloud.com/tracks/223379813/stream?client_id=f4323c6f7c0cd73d2d786a2b1cdae80c", true)
  },

  render: function() {
    return (
      <View style={styles.container}>
        <TouchableHighlight
          style={styles.button}
          onPress={this.buttonClicked}>
            <Text >Prepare!</Text>
        </TouchableHighlight>

        <TouchableHighlight
          style={styles.button}
          onPress={this.pause}>
            <Text >Pause!</Text>
        </TouchableHighlight>

         <TouchableHighlight
          style={styles.button}
          onPress={this.start}>
            <Text >Start!</Text>
        </TouchableHighlight>

      </View>
    );

```

#### LICENSE
MIT
