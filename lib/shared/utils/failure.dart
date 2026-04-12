/// Sealed Failure hierarchy — remplace dartz Left.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

final class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

// ─── Result<T> ────────────────────────────────────────────────────────────────
// Remplace Either<Failure, T> de dartz.

sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

extension ResultX<T> on Result<T> {
  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  T get value => (this as Ok<T>).value;
  Failure get failure => (this as Err<T>).failure;

  /// Equivalent de fold() de dartz.
  R fold<R>(R Function(Failure) onErr, R Function(T) onOk) => switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final failure) => onErr(failure),
      };

  /// Map sur le value si Ok, propage Err sinon.
  Result<R> map<R>(R Function(T) mapper) => switch (this) {
        Ok(:final value) => Ok(mapper(value)),
        Err(:final failure) => Err(failure),
      };
}
