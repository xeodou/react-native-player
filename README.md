## React-Native-Player

> Audio Player for React-Native

*Only Android support now.*

### Installation

First, download the library from npm:

`npm install react-native-player --save`

Then you must install the native dependencies. You can use following command to add native dependencies automatically.

`react-native link react-native-player`

or link manually like so:

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
* Register module in `MainApplication.java`
```
...
import com.xeodou.rctplayer.ReactPlayerManager;;   // Add this line

import java.util.Arrays;
import java.util.List;

public class MainApplication extends Application implements ReactApplication {

  private final ReactNativeHost mReactNativeHost = new ReactNativeHost(this) {
    @Override
    protected boolean getUseDeveloperSupport() {
      return BuildConfig.DEBUG;
    }

    @Override
    protected List<ReactPackage> getPackages() {
      return Arrays.<ReactPackage>asList(
          new MainReactPackage(),
          new ReactPlayerManager()  // Add this line
      );
    }
  };
  ...
}
```

### Usage
```
import DeviceEventEmitter from 'react-native';
import RCTAudio from 'react-native-player';

class Sample extends Component {

  componentWillMount() {
    DeviceEventEmitter.addListener('onPlayerStateChanged', (e) => console.log(e));
  }
  
  prepare() {
    RCTAudio.prepare("https://api.soundcloud.com/tracks/223379813/stream?client_id=f4323c6f7c0cd73d2d786a2b1cdae80c", false);
  }
  
  pause() {
    RCTAudio.pause();
  }
  
  play() {
    RCTAudio.start();
  }

  render: function() {
    return (
      <View style={styles.container}>
        <TouchableHighlight style={styles.button} onPress={this.prepare.bind(this)}>
            <Text >Prepare!</Text>
        </TouchableHighlight>

        <TouchableHighlight style={styles.button} onPress={this.pause.bind(this)}>
            <Text >Pause!</Text>
        </TouchableHighlight>

         <TouchableHighlight style={styles.button} onPress={this.play.bind(this)}>
            <Text >Play!</Text>
        </TouchableHighlight>

      </View>
    );
  }  
}

```

#### LICENSE
MIT
