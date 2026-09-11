package com.hemanthraj.fluttercompass;

import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.hardware.display.DisplayManager;
import android.view.Display;
import android.util.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel.EventSink;
import org.junit.Before;
import org.junit.After;
import org.junit.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.MockedStatic;
import static org.mockito.Mockito.*;

public class FlutterCompassPluginTest {
    private final FlutterCompassPlugin plugin = new FlutterCompassPlugin();
    private final SensorManager sensors = mock(SensorManager.class);
    private final FlutterPluginBinding binding = mock(FlutterPluginBinding.class);
    private final BinaryMessenger messenger = mock(BinaryMessenger.class);
    private final EventSink sink = mock(EventSink.class);
    private final Sensor rotation = mock(Sensor.class);
    private MockedStatic<Log> log;

    @Before
    public void setUp() {
        log = mockStatic(Log.class);
        Context context = mock(Context.class);
        DisplayManager displays = mock(DisplayManager.class);
        when(binding.getApplicationContext()).thenReturn(context);
        when(binding.getBinaryMessenger()).thenReturn(messenger);
        when(context.getSystemService(Context.SENSOR_SERVICE)).thenReturn(sensors);
        when(context.getSystemService(Context.DISPLAY_SERVICE)).thenReturn(displays);
        when(displays.getDisplay(Display.DEFAULT_DISPLAY)).thenReturn(mock(Display.class));
        when(sensors.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)).thenReturn(rotation);
    }

    @After
    public void tearDown() {
        log.close();
    }

    @Test
    public void detachingEngineUnregistersActiveListenerAndChannel() {
        plugin.onAttachedToEngine(binding);
        plugin.onListen(null, sink);
        ArgumentCaptor<SensorEventListener> listener = ArgumentCaptor.forClass(SensorEventListener.class);
        verify(sensors).registerListener(listener.capture(), eq(rotation), anyInt());
        plugin.onDetachedFromEngine(binding);
        verify(sensors).unregisterListener(listener.getValue());
        verify(messenger).setMessageHandler("hemanthraj/flutter_compass", null);
        plugin.onCancel(null);
        verify(sensors, times(1)).unregisterListener(listener.getValue());
    }

    @Test
    public void rotationVectorDoesNotRegisterUnusedFallbackSensors() {
        plugin.onAttachedToEngine(binding);
        plugin.onListen(null, sink);
        verify(sensors, times(1)).registerListener(any(), any(Sensor.class), anyInt());
    }

    @Test
    public void noSensorsEmitsNullInsteadOfWaitingForever() {
        when(sensors.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)).thenReturn(null);
        plugin.onAttachedToEngine(binding);
        plugin.onListen(null, sink);
        verify(sink).success(null);
        verify(sensors, never()).registerListener(any(), any(Sensor.class), anyInt());
    }

    @Test
    public void fallbackRequiresBothSensors() {
        when(sensors.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)).thenReturn(null);
        Sensor gravity = mock(Sensor.class);
        Sensor magnetic = mock(Sensor.class);
        when(sensors.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)).thenReturn(gravity);
        when(sensors.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)).thenReturn(magnetic);
        plugin.onAttachedToEngine(binding);
        plugin.onListen(null, sink);
        verify(sensors).registerListener(any(), eq(gravity), anyInt());
        verify(sensors).registerListener(any(), eq(magnetic), anyInt());
        verifyNoInteractions(sink);
    }

    @Test
    public void repeatedListenReleasesPreviousSubscription() {
        plugin.onAttachedToEngine(binding);
        plugin.onListen(null, sink);
        ArgumentCaptor<SensorEventListener> listener = ArgumentCaptor.forClass(SensorEventListener.class);
        verify(sensors).registerListener(listener.capture(), eq(rotation), anyInt());
        plugin.onListen(null, sink);
        verify(sensors).unregisterListener(listener.getValue());
        verify(sensors, times(2)).registerListener(any(), eq(rotation), anyInt());
    }
}
