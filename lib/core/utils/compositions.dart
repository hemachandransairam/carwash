import "package:flutter/widgets.dart";
import "package:signals_flutter/signals_flutter.dart" as s;

/// A simple shim for flutter_compositions using signals.
/// This allows the project to follow the requested Clean Architecture rules
/// even on Dart SDKs below 3.9.0.

class Ref<T> {
  const Ref(this._signal);
  final s.Signal<T> _signal;

  T get value => _signal.value;
  set value(T newValue) => _signal.value = newValue;
}

Ref<T> ref<T>(T initialValue) => Ref(s.signal(initialValue));

class Computed<T> {
  const Computed(this._signal);
  final s.ReadonlySignal<T> _signal;

  T get value => _signal.value;
}

Computed<T> computed<T>(T Function() getter) => Computed(s.computed(getter));

T useComposable<T>(T Function() factory) {
  // In a real implementation this might use a hook,
  // but for state management classes we just return the instance.
  return factory();
}

class Observer extends StatelessWidget {
  const Observer({required this.builder, super.key});
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return s.Watch((context) => builder(context));
  }
}
