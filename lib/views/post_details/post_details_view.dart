import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:instagram_clone_course/enums/date_sorting.dart';
import 'package:instagram_clone_course/state/comments/models/post_comments_request.dart';
import 'package:instagram_clone_course/state/posts/models/post.dart';
import 'package:instagram_clone_course/state/posts/providers/can_current_user_delete_post_provider.dart';
import 'package:instagram_clone_course/state/posts/providers/delete_post_provider.dart';
import 'package:instagram_clone_course/state/posts/providers/specific_post_with_comments_provider.dart';
import 'package:instagram_clone_course/views/components/animations/error_animation_view.dart';
import 'package:instagram_clone_course/views/components/animations/loading_animation_view.dart';
import 'package:instagram_clone_course/views/components/animations/small_error_animation_view.dart';
import 'package:instagram_clone_course/views/components/comment/compact_comment_column.dart';
import 'package:instagram_clone_course/views/components/dialogs/alert_dialog_model.dart';
import 'package:instagram_clone_course/views/components/dialogs/delete_dialog.dart';
import 'package:instagram_clone_course/views/components/like_button.dart';
import 'package:instagram_clone_course/views/components/likes_count_view.dart';
import 'package:instagram_clone_course/views/components/post/post_date_view.dart';
import 'package:instagram_clone_course/views/components/post/post_display_name_and_message_view.dart';
import 'package:instagram_clone_course/views/components/post/post_image_or_video_view.dart';
import 'package:instagram_clone_course/views/constants/strings.dart';
import 'package:instagram_clone_course/views/post_comments/post_comments_view.dart';
import 'package:share_plus/share_plus.dart';

class PostDetailsView extends ConsumerStatefulWidget {
  final Post post;
  const PostDetailsView({
    super.key,
    required this.post,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _PostDetailsViewState();
}

class _PostDetailsViewState extends ConsumerState<PostDetailsView> {
  @override
  Widget build(BuildContext context) {
    final request = RequestForPostAndComments(
      postId: widget.post.postId,
      limit: 3,
      sortByCreatedAt: true,
      dateSorting: DateSorting.oldestOnTop,
    );

    // get the actual post together with its comments
    final postWithComments = ref.watch(
      specificPostWithCommentsProvider(
        request,
      ),
    );

    // can we delete this post?

    final canDeletePost = ref.watch(
      canCurrentUserDeletePostProvider(
        widget.post,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          Strings.postDetails,
        ),
        actions: [
          // share button is always present
          postWithComments.when(
            data: (postWithComments) {
              return IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  final url = postWithComments.post.fileUrl;
                  Share.share(
                    url,
                    subject: Strings.checkOutThisPost,
                  );
                },
              );
            },
            error: (error, stackTrace) {
              return const SmallErrorAnimationView();
            },
            loading: () {
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
          // delete button or no delete button if user cannot delete this post
          if (canDeletePost.value ?? false)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final shouldDeletePost = await const DeleteDialog(
                  titleOfObjectToDelete: Strings.post,
                ).present(context).then(
                      (shouldDelete) => shouldDelete ?? false,
                    );
                if (shouldDeletePost) {
                  await ref.read(deletePostProvider.notifier).deletePost(
                        post: widget.post,
                      );
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                }
              },
            )
        ],
      ),
      body: postWithComments.when(
        data: (postWithComments) {
          final postId = postWithComments.post.postId;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PostImageOrVideoView(
                  post: postWithComments.post,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // like button if post allows liking
                    if (postWithComments.post.allowLikes)
                      LikeButton(
                        postId: postId,
                      ),
                    // comment button if post allows commenting on it
                    if (postWithComments.post.allowComments)
                      IconButton(
                        icon: const Icon(
                          Icons.mode_comment_outlined,
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PostCommentsView(
                                postId: postId,
                              ),
                            ),
                          );
                        },
                      )
                  ],
                ),
                // post details (show divider at bottom)
                PostDisplayNameAndMessageView(
                  post: postWithComments.post,
                ),
                PostDateView(
                  dateTime: postWithComments.post.createdAt,
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Divider(
                    color: Colors.white70,
                  ),
                ),
                // comments
                CompactCommentColumn(
                  comments: postWithComments.comments,
                ),
                // display like count
                if (postWithComments.post.allowLikes)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        LikesCountView(
                          postId: postId,
                        ),
                      ],
                    ),
                  ),
                // add spacing to bottom of screen
                const SizedBox(
                  height: 100,
                ),
              ],
            ),
          );
        },
        error: (error, stackTrace) {
          return const ErrorAnimationView();
        },
        loading: () {
          return const LoadingAnimationView();
        },
      ),
    );
  }
}
