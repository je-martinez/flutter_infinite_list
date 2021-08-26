import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_infinite_list/posts/models/post.dart';
import 'package:rxdart/rxdart.dart';

part 'post_event.dart';
part 'post_state.dart';

const _postLimit = 20;

class PostBloc extends Bloc<PostEvent, PostState> {
  PostBloc({required this.httpClient}) : super(const PostState());

  final http.Client httpClient;

@override
Stream<Transition<PostEvent, PostState>> transformEvents(
  Stream<PostEvent> events,
  TransitionFunction<PostEvent, PostState> transitionFn,
) {
  return super.transformEvents(
    events.throttleTime(const Duration(milliseconds: 500)),
    transitionFn,
  );
}

  @override
  Stream<PostState> mapEventToState(
    PostEvent event,
  ) async* {
    if(event is PostFetched){
      yield await _mapPostFetchedToState(state);
    }
  }

  Future<PostState> _mapPostFetchedToState(PostState state) async{
    if(state.hasReachedMax) return state;
    try{
      if(state.status == PostStatus.initial){
        final posts = await _fetchPosts();
        return state.copyWith(
          status: PostStatus.success,
          posts: posts,
          hasReachedMax: false 
        );
      }
      final posts = await _fetchPosts(state.posts.length);
      return posts.isEmpty 
              ? state.copyWith(hasReachedMax: true)
              : state.copyWith(
                status: PostStatus.success,
                posts: List.of(state.posts)..addAll(posts),
                hasReachedMax: false
              );
    } on Exception{
      return state.copyWith(status: PostStatus.failure);
    }
  }

  Future <List<Post>> _fetchPosts([int startIndex = 0]) async {
    const String _url = 'jsonplaceholder.typicode.com';
    const String _postPrefix = '/posts';
    final Map<String, String> _params = <String, String>{'_start': '$startIndex', '_limit': '$_postLimit'};
    Uri requestPostsUri = Uri.https(_url, _postPrefix, _params);
    final response = await httpClient.get(requestPostsUri);
    if(response.statusCode == 200){
      final body = json.decode((response.body)) as List;
      return body.map((dynamic json) {
        return Post(
            id: json['id'] as int,
            title: json['title'] as String,
            body: json['body'] as String
          );
      }).toList();
    }
    throw Exception('error fetching posts');
  }

  
}
