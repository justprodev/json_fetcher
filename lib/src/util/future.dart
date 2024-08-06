// Created by alex@justprodev.com on 06.08.2024.

extension Errors<T> on Future<T> {
  /// convenient variant with possibility to use nullable callback,
  /// and omitting [Future.catchError] test parameter, i.e. [onError] always will be called
  Future<T> catchErrors(Function? onError) {
    if (onError != null) return catchError(onError);
    return this;
  }
}
