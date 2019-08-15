# oauth module for Trigger.io

This repository holds everything required to build the oauth [Trigger.io](https://trigger.io/) module.

For more information about working on Trigger.io native modules, see [the documentation](https://trigger.io/docs/current/api/native_modules/index.html).


## Building AppAuth-iOS static library

```
git clone https://github.com/openid/AppAuth-iOS.git
DESTPATH=~/Projects/modules/trigger.io-oauth.git/inspector/ios-inspector/ForgeModule
CONF=Debug

rm -rf build

# Compile Framework
xcodebuild -configuration $CONF -target AppAuth-iOS ARCHS="arm64"
xcodebuild -configuration $CONF -target AppAuth-iOS ARCHS="x86_64" -sdk iphonesimulator
xcodebuild -configuration $CONF -target AppAuth_iOS ARCHS="arm64"
xcodebuild -configuration $CONF -target AppAuth_iOS ARCHS="x86_64" -sdk iphonesimulator

# Copy Framework
rm -rf $DESTPATH/AppAuth.framework
cp -r build/$CONF-iphoneos/AppAuth.framework $DESTPATH/AppAuth.framework

# Create Fat Binaries
lipo -create -output $DESTPATH/libAppAuth-iOS.a \
     ./build/$CONF-iphoneos/libAppAuth-iOS.a \
     ./build/$CONF-iphonesimulator/libAppAuth-iOS.a

lipo -create -output $DESTPATH/AppAuth.framework/AppAuth \
     ./build/$CONF-iphoneos/AppAuth.framework/AppAuth \
     ./build/$CONF-iphonesimulator/AppAuth.framework/AppAuth

```


## References

* https://github.com/openid/AppAuth-iOS/issues/356
* https://github.com/openid/AppAuth-iOS/issues/367
* https://github.com/openid/AppAuth-iOS/issues/232
