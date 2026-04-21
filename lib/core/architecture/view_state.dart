sealed class ViewState<T> {
  const ViewState();
}

class Initial<T> extends ViewState<T> {
  const Initial();
}

class Loading<T> extends ViewState<T> {
  const Loading();
}

class Success<T> extends ViewState<T> {
  final T data;
  const Success(this.data);
}

class Error<T> extends ViewState<T> {
  final String message;
  const Error(this.message);
}
