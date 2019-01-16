package moha.moe.nativewebview;

import android.content.Context;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class FlutterWebViewFactory extends PlatformViewFactory {
    BinaryMessenger binaryMessenger;

    public FlutterWebViewFactory(BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.binaryMessenger = messenger;
    }

    @Override
    public PlatformView create(Context context, int i, Object o) {
        Map<String, Object> params = (Map<String, Object>) o;
        return new FlutterWebView(context, binaryMessenger, i, params);
    }
}
