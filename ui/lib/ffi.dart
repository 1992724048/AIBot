import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FFIException implements Exception {
  final String code;
  final String message;

  FFIException(this.code, this.message);

  @override
  String toString() => 'FFIException($code): $message';
}

class Dart {
  final String name;

  const Dart(this.name);

  void method(Future<dynamic> Function(Map? args) handler) {
    FFI.registerMethod(name, handler);
  }

  Future<dynamic> invoke([Map<String, dynamic>? params]) async {
    return FFI.invoke(name, params: params);
  }

  static Dart of(String name) => Dart(name);
}

extension CppStringLiteral on String {
  Dart get cpp => Dart(this);
}

class FFIEventBus {
  static final FFIEventBus _instance = FFIEventBus._internal();

  factory FFIEventBus() => _instance;

  FFIEventBus._internal();

  final _controllers = <String, StreamController<dynamic>>{};
  final _subscriptions = <String, List<StreamSubscription>>{};

  Stream<dynamic> on(String event) {
    if (!_controllers.containsKey(event)) {
      _controllers[event] = StreamController<dynamic>.broadcast();
    }
    return _controllers[event]!.stream;
  }

  void emit(String event, dynamic data) {
    if (_controllers.containsKey(event)) {
      _controllers[event]!.add(data);
    }
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _subscriptions.clear();
  }
}

abstract final class FFI {
  FFI._();

  static const MethodChannel _channel = MethodChannel('ffi_cpp');
  static bool isSetMethodCallHandler = false;
  static final Map<String, Future<dynamic> Function(Map?)> _methodHandler = {};
  static final eventBus = FFIEventBus();

  static void _ensureInitialized() {
    if (!isSetMethodCallHandler) {
      _channel.setMethodCallHandler(_onPlatformCall);
      isSetMethodCallHandler = true;
    }
  }

  static Future<dynamic> invoke(String method, {Map<String, dynamic>? params}) async {
    try {
      final Map<String, dynamic> arguments = {if (params != null) ...params};
      return _channel.invokeMethod(method, arguments);
    } on PlatformException catch (e) {
      throw FFIException(e.code, "${e.message ?? 'Unknown platform error'}\nMethod: $method\nParams:$params");
    } catch (e, s) {
      debugPrint('[$FFI] invoke($method) error: $e\n$s');
      throw FFIException('INVOKE_ERROR', "$e\nMethod: $method\nParams:$params");
    }
  }

  static void registerMethod(String method, Future<dynamic> Function(Map? args) handler) {
    _ensureInitialized();
    _methodHandler[method] = handler;
  }

  static void unregisterMethod(String method) => _methodHandler.remove(method);

  static Future<dynamic> _onPlatformCall(MethodCall call) async {
    if (call.method.startsWith('notifier_')) {
      eventBus.emit(call.method, call.arguments);
      return null;
    }

    if (!_methodHandler.containsKey(call.method)) {
      throw MissingPluginException('FFI: method "${call.method}" not registered on Dart side');
    }
    final handler = _methodHandler[call.method];
    if (handler == null) {
      throw MissingPluginException('FFI: method "${call.method}" call is null');
    }
    try {
      return await handler(call.arguments as Map?);
    } catch (e, s) {
      debugPrint('[$FFI] handler(${call.method}) throw: $e\n$s');
      rethrow;
    }
  }
}

typedef EncodableList = List<dynamic>;
typedef EncodableMap = Map<String, dynamic>;

typedef float = double;

abstract class Field<T> extends ChangeNotifier implements ValueListenable<T> {
  final String name;
  T _value;
  bool _disposed = false;
  late final StreamSubscription _subscription;
  void Function(Object error, StackTrace stack)? onError;

  Field._internal(this.name, this._value, {this.onError}) {
    _setupListener();
  }

  void _setupListener() {
    try {
      _subscription = FFI.eventBus
          .on('notifier_$name')
          .listen(
            (data) {
              if (_disposed) return;
              try {
                if (data is Map && data.containsKey('value')) {
                  final newValue = _fromDynamic(data['value']);
                  if (newValue != null && newValue != _value) {
                    _value = newValue;
                    notifyListeners();
                  }
                }
              } catch (e) {
                onError?.call(FFIException('LISTENER_PROCESS_ERROR', 'Field $name process notification error: $e'), StackTrace.current);
              }
            },
            onError: (error) {
              onError?.call(FFIException('LISTENER_ERROR', 'Field $name listener error: $error'), StackTrace.current);
            },
          );
    } catch (e) {
      onError?.call(FFIException('LISTENER_SETUP_ERROR', 'Field $name setup listener error: $e'), StackTrace.current);
    }
  }

  Future<T> get() async {
    try {
      final result = await FFI.invoke('get_$name');
      if (result == null) {
        return value;
      }
      final converted = _fromDynamic(result);
      if (converted != null) {
        if (converted != _value) {
          _value = converted;
          if (!_disposed) {
            notifyListeners();
          }
        }
        return _value;
      }
      throw FFIException('TYPE_MISMATCH', 'Cannot convert get_$name result to ${T.toString()}');
    } on FFIException {
      rethrow;
    } catch (e) {
      throw FFIException('GET_ERROR', 'Failed to get field $name: ${e.toString()}');
    }
  }

  Future<bool> set(T newValue) async {
    if (_value == newValue) return true;

    final oldValue = _value;

    try {
      await FFI.invoke('set_$name', params: {'value': _toDynamic(newValue)});

      _value = newValue;
      if (!_disposed) {
        notifyListeners();
      }
    } catch (e) {
      _value = oldValue;
      if (!_disposed) {
        notifyListeners();
      }
      throw FFIException('SET_ERROR', 'Failed to set field $name: ${e.toString()}');
    }
    return true;
  }

  void updateValue(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  @override
  T get value => _value;

  Future<T> refresh() async {
    return await get();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription.cancel();
    super.dispose();
  }

  T? _fromDynamic(dynamic value) {
    if (value == null) return null;

    try {
      if (T == int || T is int) {
        if (value is int) return value as T;
        if (value is double) return value.toInt() as T;
        if (value is String) return int.tryParse(value) as T?;
      } else if (T == double || T is double || T == float || T is float) {
        if (value is double) return value as T;
        if (value is int) return value.toDouble() as T;
        if (value is String) return double.tryParse(value) as T?;
      } else if (T == String || T is String) {
        return value.toString() as T;
      } else if (T == bool || T is bool) {
        if (value is bool) return value as T;
        if (value is int) return (value != 0) as T;
        if (value is String) return (value.toLowerCase() == 'true') as T;
      } else if (T == Uint8List || T is Uint8List) {
        if (value is Uint8List) return value as T;
        if (value is List) return Uint8List.fromList(List<int>.from(value)) as T;
      } else if (T == Int32List || T is Int32List) {
        if (value is Int32List) return value as T;
        if (value is List) return Int32List.fromList(List<int>.from(value)) as T;
      } else if (T == Int64List || T is Int64List) {
        if (value is Int64List) return value as T;
        if (value is List) return Int64List.fromList(List<int>.from(value)) as T;
      } else if (T == Float32List || T is Float32List) {
        if (value is Float32List) return value as T;
        if (value is List) return Float32List.fromList(List<double>.from(value)) as T;
      } else if (T == Float64List || T is Float64List) {
        if (value is Float64List) return value as T;
        if (value is List) return Float64List.fromList(List<double>.from(value)) as T;
      } else if (value is List) {
        if (T == EncodableList || T is EncodableList) {
          return value as T;
        }

        try {
          if (value.isEmpty) {
            return <dynamic>[] as T;
          }

          final firstElement = value.first;

          if (firstElement is int) {
            return value.map((e) => e is int ? e : e?.toInt()).toList() as T;
          } else if (firstElement is double) {
            return value.map((e) => e is double ? e : e?.toDouble()).toList() as T;
          } else if (firstElement is String) {
            return value.map((e) => e.toString()).toList() as T;
          } else if (firstElement is bool) {
            return value.map((e) {
                  if (e is bool) return e;
                  if (e is int) return e != 0;
                  if (e is String) return e.toLowerCase() == 'true';
                  return false;
                }).toList()
                as T;
          }

          return value as T;
        } catch (e) {
          return value as T;
        }
      } else if (value is Map) {
        if (T == EncodableMap || T is EncodableMap) {
          return value as T;
        }
      }

      try {
        return value as T;
      } catch (e) {
        return null;
      }
    } catch (e) {
      onError?.call(FFIException('TYPE_CONVERSION_ERROR', 'Field $name type conversion error: $e'), StackTrace.current);
      return null;
    }
  }

  dynamic _toDynamic(T value) {
    try {
      if (value is int || value is double || value is String || value is bool) {
        return value;
      }

      if (value is Uint8List) {
        return value;
      }
      if (value is Int32List) {
        return value;
      }
      if (value is Int64List) {
        return value;
      }
      if (value is Float32List) {
        return value;
      }
      if (value is Float64List) {
        return value;
      }

      if (value is List) {
        return value.map((e) => _toDynamicElement(e)).toList();
      }

      if (value is Map) {
        return Map.fromEntries(value.entries.map((e) => MapEntry(e.key.toString(), _toDynamicElement(e.value))));
      }

      return value.toString();
    } catch (e) {
      onError?.call(FFIException('TO_DYNAMIC_ERROR', 'Field $name toDynamic conversion error: $e'), StackTrace.current);
      return value.toString();
    }
  }

  dynamic _toDynamicElement(dynamic element) {
    try {
      if (element is int || element is double || element is String || element is bool) {
        return element;
      }
      if (element is List) {
        return element.map((e) => _toDynamicElement(e)).toList();
      }
      if (element is Map) {
        return Map.fromEntries(element.entries.map((e) => MapEntry(e.key.toString(), _toDynamicElement(e.value))));
      }
      return element.toString();
    } catch (e) {
      return element.toString();
    }
  }
}

class FieldFactory {
  static final Map<String, Field> _instances = {};

  static IntField intField(String name, int defaultValue) {
    final key = 'int:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = IntField._internal(name, defaultValue);
    }
    return _instances[key] as IntField;
  }

  static FloatField floatField(String name, float defaultValue) {
    final key = 'float:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = FloatField._internal(name, defaultValue);
    }
    return _instances[key] as FloatField;
  }

  static DoubleField doubleField(String name, double defaultValue) {
    final key = 'double:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = DoubleField._internal(name, defaultValue);
    }
    return _instances[key] as DoubleField;
  }

  static StringField stringField(String name, String defaultValue) {
    final key = 'string:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = StringField._internal(name, defaultValue);
    }
    return _instances[key] as StringField;
  }

  static BoolField boolField(String name, bool defaultValue) {
    final key = 'bool:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = BoolField._internal(name, defaultValue);
    }
    return _instances[key] as BoolField;
  }

  static IntListField intListField(String name, List<int> defaultValue) {
    final key = 'intList:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = IntListField._internal(name, defaultValue);
    }
    return _instances[key] as IntListField;
  }

  static Int32ListField int32ListField(String name, Int32List defaultValue) {
    final key = 'int32List:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = Int32ListField._internal(name, defaultValue);
    }
    return _instances[key] as Int32ListField;
  }

  static Int64ListField int64ListField(String name, Int64List defaultValue) {
    final key = 'int64List:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = Int64ListField._internal(name, defaultValue);
    }
    return _instances[key] as Int64ListField;
  }

  static Float32ListField float32ListField(String name, Float32List defaultValue) {
    final key = 'float32List:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = Float32ListField._internal(name, defaultValue);
    }
    return _instances[key] as Float32ListField;
  }

  static Float64ListField float64ListField(String name, Float64List defaultValue) {
    final key = 'float64List:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = Float64ListField._internal(name, defaultValue);
    }
    return _instances[key] as Float64ListField;
  }

  static StringListField stringListField(String name, List<String> defaultValue) {
    final key = 'stringList:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = StringListField._internal(name, defaultValue);
    }
    return _instances[key] as StringListField;
  }

  static BoolListField boolListField(String name, List<bool> defaultValue) {
    final key = 'boolList:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = BoolListField._internal(name, defaultValue);
    }
    return _instances[key] as BoolListField;
  }

  static Uint8ListField uint8ListField(String name, Uint8List defaultValue) {
    final key = 'uint8List:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = Uint8ListField._internal(name, defaultValue);
    }
    return _instances[key] as Uint8ListField;
  }

  static EncodableListField encodableListField(String name, EncodableList defaultValue) {
    final key = 'encodableList:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = EncodableListField._internal(name, defaultValue);
    }
    return _instances[key] as EncodableListField;
  }

  static EncodableMapField encodableMapField(String name, EncodableMap defaultValue) {
    final key = 'encodableMap:$name';
    if (!_instances.containsKey(key)) {
      _instances[key] = EncodableMapField._internal(name, defaultValue);
    }
    return _instances[key] as EncodableMapField;
  }

  static bool has(String name, {Type? type}) {
    if (type != null) {
      final key = '${type.toString().split('.').last.toLowerCase()}:$name';
      return _instances.containsKey(key);
    }
    return _instances.values.any((f) => f.name == name);
  }

  static Field? get(String name) {
    try {
      return _instances.values.firstWhere((f) => f.name == name);
    } catch (e) {
      return null;
    }
  }
}

class IntField extends Field<int> {
  IntField._internal(super.name, super.defaultValue) : super._internal();

  factory IntField(String name, int defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.intField(name, defaultValue)..onError = onError;
  }
}

class FloatField extends Field<float> {
  FloatField._internal(super.name, super.defaultValue) : super._internal();

  factory FloatField(String name, float defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.floatField(name, defaultValue)..onError = onError;
  }
}

class DoubleField extends Field<double> {
  DoubleField._internal(super.name, super.defaultValue) : super._internal();

  factory DoubleField(String name, double defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.doubleField(name, defaultValue)..onError = onError;
  }
}

class StringField extends Field<String> {
  StringField._internal(super.name, super.defaultValue) : super._internal();

  factory StringField(String name, String defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.stringField(name, defaultValue)..onError = onError;
  }
}

class BoolField extends Field<bool> {
  BoolField._internal(super.name, super.defaultValue) : super._internal();

  factory BoolField(String name, bool defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.boolField(name, defaultValue)..onError = onError;
  }
}

class IntListField extends Field<List<int>> {
  IntListField._internal(super.name, super.defaultValue) : super._internal();

  factory IntListField(String name, List<int> defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.intListField(name, defaultValue)..onError = onError;
  }
}

class Int32ListField extends Field<Int32List> {
  Int32ListField._internal(super.name, super.defaultValue) : super._internal();

  factory Int32ListField(String name, Int32List defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.int32ListField(name, defaultValue)..onError = onError;
  }
}

class Int64ListField extends Field<Int64List> {
  Int64ListField._internal(super.name, super.defaultValue) : super._internal();

  factory Int64ListField(String name, Int64List defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.int64ListField(name, defaultValue)..onError = onError;
  }
}

class Float32ListField extends Field<Float32List> {
  Float32ListField._internal(super.name, super.defaultValue) : super._internal();

  factory Float32ListField(String name, Float32List defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.float32ListField(name, defaultValue)..onError = onError;
  }
}

class Float64ListField extends Field<Float64List> {
  Float64ListField._internal(super.name, super.defaultValue) : super._internal();

  factory Float64ListField(String name, Float64List defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.float64ListField(name, defaultValue)..onError = onError;
  }
}

class StringListField extends Field<List<String>> {
  StringListField._internal(super.name, super.defaultValue) : super._internal();

  factory StringListField(String name, List<String> defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.stringListField(name, defaultValue)..onError = onError;
  }
}

class BoolListField extends Field<List<bool>> {
  BoolListField._internal(super.name, super.defaultValue) : super._internal();

  factory BoolListField(String name, List<bool> defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.boolListField(name, defaultValue)..onError = onError;
  }
}

class Uint8ListField extends Field<Uint8List> {
  Uint8ListField._internal(super.name, super.defaultValue) : super._internal();

  factory Uint8ListField(String name, Uint8List defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.uint8ListField(name, defaultValue)..onError = onError;
  }
}

class EncodableListField extends Field<EncodableList> {
  EncodableListField._internal(super.name, super.defaultValue) : super._internal();

  factory EncodableListField(String name, EncodableList defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.encodableListField(name, defaultValue)..onError = onError;
  }
}

class EncodableMapField extends Field<EncodableMap> {
  EncodableMapField._internal(super.name, super.defaultValue) : super._internal();

  factory EncodableMapField(String name, EncodableMap defaultValue, {void Function(Object error, StackTrace stack)? onError}) {
    return FieldFactory.encodableMapField(name, defaultValue)..onError = onError;
  }
}
