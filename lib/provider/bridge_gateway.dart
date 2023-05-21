import 'dart:async';
import 'dart:convert';

import 'package:darttonconnect/async/async.dart';
import 'package:http/http.dart';
import 'package:universal_html/html.dart';

import 'package:darttonconnect/exceptions.dart';
import 'package:darttonconnect/logger.dart';
import 'package:darttonconnect/storage/interface.dart';

class BridgeGateway {
  static const String ssePath = 'events';
  static const String postPath = 'message';
  static const int defaultTtl = 300;

  late Completer<bool> resolve;
  late EventSource _eventSource;
  AsyncTask? handleListen;
  bool _isClosed = false;

  final IStorage _storage;
  final String _bridgeUrl;
  final String _sessionId;
  final Function _listener;
  final Function? _errorsListener;

  BridgeGateway(this._storage, this._bridgeUrl, this._sessionId, this._listener,
      this._errorsListener) {
    resolve = Completer();
  }

  Future<void> listenEventSource() async {
    try {
      await for (var event in _eventSource.onMessage) {
        await _messagesHandler(event);
      }
    } on TimeoutException {
      print('Bridge error -> TimeoutError');
    } on ClientException {
      print('Bridge error -> ClientConnectionError');
    } catch (e) {
      print('Bridge error -> Unknown');
      print(e);
    }

    if (!resolve.isCompleted) {
      resolve.complete(false);
    }
  }

  Future<bool> registerSession() async {
    if (_isClosed) {
      return false;
    }

    final bridgeBase = _bridgeUrl.replaceFirst(RegExp(r'/*$'), '');
    var bridgeUrl = '$bridgeBase/$ssePath?client_id=$_sessionId';

    final lastEventId = await _storage.getItem(key: IStorage.keyLastEventId);
    if (lastEventId != null) {
      bridgeUrl += '&last_event_id=$lastEventId';
    }

    logger.d('Bridge url -> $bridgeUrl');

    _eventSource = EventSource(bridgeUrl, withCredentials: true);

    _eventSource.onError.listen(_errorsHandler);

    _eventSource.onOpen.listen((_) {
      resolve.complete(true);
    });

    _eventSource.onMessage.listen((event) async {
      await _messagesHandler(event);
    });

    return await resolve.future;
  }

  Future<void> send(String request, String receiverPublicKey, String topic,
      {int? ttl}) async {
    final bridgeBase = _bridgeUrl.replaceFirst(RegExp(r'/*$'), '');
    var bridgeUrl = '$bridgeBase/$postPath?client_id=$_sessionId';
    final ttlValue = ttl ?? defaultTtl;
    bridgeUrl += '&to=$receiverPublicKey&ttl=$ttlValue&topic=$topic';

    final xhr = HttpRequest();
    xhr.open('POST', bridgeUrl);
    xhr.setRequestHeader('Content-Type', 'application/json; charset=utf-8');
    xhr.send(request);
  }

  void pause() {
    _eventSource.close();
  }

  Future<void> unpause() async {
    await registerSession();
  }

  Future<void> close() async {
    _isClosed = true;
    _eventSource.close();
  }

  void _errorsHandler(Event event) {
    if (!_isClosed) {
      switch (_eventSource.readyState) {
        case EventSource.CLOSED:
          logger.e('Bridge error -> CLOSED');
          // TODO: reconnect
          break;
        case EventSource.CONNECTING:
          logger.e('Bridge error -> CONNECTING');
          break;
        default:
          break;
      }

      if (_errorsListener != null) {
        _errorsListener!();
      }
    }
  }

  Future<void> _messagesHandler(MessageEvent event) async {
    final data = jsonDecode(event.data);
    await _storage.setItem(
        key: IStorage.keyLastEventId, value: data['last_event_id']);

    if (!_isClosed) {
      try {
        await _listener(data);
      } catch (e) {
        throw TonConnectError('Bridge listener failed');
      }
    }
  }
}
