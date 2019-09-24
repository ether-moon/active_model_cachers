# frozen_string_literal: true
require 'base_test'

class CacheAtHasManyTest < BaseTest
  def test_basic_usage
    user = User.find_by(name: 'John1')
    posts = user.posts

    assert_queries(1){ assert_equal 3, User.cacher_at(user.id).posts.size }
    assert_queries(0){ assert_equal 3, User.cacher_at(user.id).posts.size }
    assert_cache('active_model_cachers_User_at_posts_1' => posts)
  end

  def test_basic_usage_of_instance_cacher
    user = User.find_by(name: 'John1')

    assert_queries(1){ assert_equal 3, user.cacher.posts.size }
    assert_queries(0){ assert_equal 3, user.cacher.posts.size }
    assert_cache('active_model_cachers_User_at_posts_1' => user.posts)
  end

  def test_instance_cacher_without_association_cache
    user1 = User.find_by(name: 'John1')
    user2 = User.find_by(name: 'John1')

    assert_queries(1){ assert_equal 3, user1.cacher.posts.size }
    assert_queries(0){ assert_equal 3, user2.cacher.posts.size }
    assert_cache('active_model_cachers_User_at_posts_1' => user1.posts)
  end

  def test_instance_cacher_to_use_loaded_associations
    user = User.find_by(name: 'John1')
    posts = user.posts.to_a # to_a to make sure posts is loaded

    assert_queries(0){ assert_equal 3, user.cacher.posts.size }
    assert_cache('active_model_cachers_User_at_posts_1' => posts)
  end

  def test_instance_cacher_to_use_preloaded_associations
    user = User.includes(:posts).find_by(name: 'John1')

    assert_queries(0){ assert_equal 3, user.cacher.posts.size }
    assert_cache('active_model_cachers_User_at_posts_1' => user.posts)
  end

  # ----------------------------------------------------------------
  # ● Create
  # ----------------------------------------------------------------
  def test_create
    user = User.find_by(name: 'John1')
    posts = user.posts
    new_post = nil

    assert_queries(1){ assert_equal 3, User.cacher_at(user.id).posts.size }
    assert_queries(0){ assert_equal 3, User.cacher_at(user.id).posts.size }
    assert_cache('active_model_cachers_User_at_posts_1' => posts)

    assert_queries(1){ new_post = Post.create(id: -1, user: user) }
    assert_cache({})

    assert_queries(1){ assert_equal 4, User.cacher_at(user.id).posts.size }
    assert_queries(0){ assert_equal 4, User.cacher_at(user.id).posts.size }
    assert_cache('active_model_cachers_User_at_posts_1' => [new_post, *posts])
  ensure
    new_post.delete if new_post
  end

  # ----------------------------------------------------------------
  # ● Assign
  # ----------------------------------------------------------------
  def test_assign_association
    user = User.create(id: -1)
    post1 = Post.create(id: -3)
    post2 = Post.create(id: -2)

    assert_queries(1){ assert_equal [], user.cacher.posts }
    assert_queries(0){ assert_equal [], user.cacher.posts }
    assert_cache('active_model_cachers_User_at_posts_-1' => [])

    assert_queries(1){ user.posts << post1 }
    assert_cache({})

    assert_queries(0){ assert_equal [post1], user.cacher.posts}
    assert_cache('active_model_cachers_User_at_posts_-1' => [post1])

    assert_queries(1){ user.posts << post2 }
    assert_cache({})

    assert_queries(1){ assert_equal [post1, post2], User.cacher_at(-1).posts}
    assert_cache('active_model_cachers_User_at_posts_-1' => [post1, post2])
  ensure
    user.delete if user
    post1.delete if post1
    post2.delete if post2
  end

  # ----------------------------------------------------------------
  # ● Clean
  # ----------------------------------------------------------------
  def test_clean
    user = User.find_by(name: 'John1')

    Rails.cache.write('active_model_cachers_User_at_posts_1', user.posts)
    assert_cache('active_model_cachers_User_at_posts_1' => user.posts)

    assert_queries(0){ User.cacher_at(user.id).clean_posts }
    assert_cache({})
  end

  def test_clean2
    user = User.find_by(name: 'John1')

    Rails.cache.write('active_model_cachers_User_at_posts_1', user.posts)
    assert_cache('active_model_cachers_User_at_posts_1' => user.posts)

    assert_queries(0){ User.cacher_at(user.id).clean(:posts) }
    assert_cache({})
  end

  def test_clean_in_instance_cacher
    user = User.find_by(name: 'John1')

    Rails.cache.write('active_model_cachers_User_at_posts_1', user.posts)
    assert_cache('active_model_cachers_User_at_posts_1' => user.posts)

    assert_queries(0){ user.cacher.clean_posts }
    assert_cache({})
  end

  # ----------------------------------------------------------------
  # ● Update
  # ----------------------------------------------------------------
  def test_update_nothing
    user = User.find_by(name: 'John4')
    post = Post.create(id: -1, user: user)

    assert_queries(1){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_queries(0){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_cache('active_model_cachers_User_at_posts_4' => [post])

    assert_queries(0){ post.save }
    assert_cache('active_model_cachers_User_at_posts_4' => [post])

    assert_queries(0){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_cache('active_model_cachers_User_at_posts_4' => [post])
  ensure
    post.delete
  end

  def test_update_title
    user = User.find_by(name: 'John4')
    post = Post.create(id: -1, user: user)

    assert_queries(1){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_queries(0){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_cache('active_model_cachers_User_at_posts_4' => [post])

    assert_queries(1){ post.update(title: '學生退出校園') }
    assert_cache({})

    assert_queries(1){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_queries(0){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_cache('active_model_cachers_User_at_posts_4' => [post])
  ensure
    post.delete if post
  end

  def test_update_others_post_title
    user1 = User.find_by(name: 'John4')
    user2 = User.find_by(name: 'John1')
    post = Post.create(id: -1, user: user2)

    assert_queries(1){ assert_equal [], User.cacher_at(user1.id).posts }
    assert_queries(0){ assert_equal [], User.cacher_at(user1.id).posts }
    assert_cache('active_model_cachers_User_at_posts_4' => [])

    assert_queries(1){ post.update(title: '學生退出校園') }
    assert_cache('active_model_cachers_User_at_posts_4' => [])

    assert_queries(0){ assert_equal [], User.cacher_at(user1.id).posts }
    assert_cache('active_model_cachers_User_at_posts_4' => [])
  ensure
    post.delete if post
  end

  def test_update_title_without_select_foreign_key
    user = User.find_by(name: 'John4')
    post = Post.create(id: -1, user: user)
    post_with_only_title = Post.select('id, title').find_by(id: -1)

    assert_queries(1){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_queries(0){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_cache('active_model_cachers_User_at_posts_4' => [post])

    assert_queries(2){ post_with_only_title.update(title: '學生退出校園') } # send extra query to select user_id
    assert_cache({})

    assert_queries(1){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_queries(0){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_cache('active_model_cachers_User_at_posts_4' => [post])
  ensure
    post.delete if post
  end

  # ----------------------------------------------------------------
  # ● Destroy
  # ----------------------------------------------------------------
  def test_destroy
    user = User.find_by(name: 'John4')
    post = Post.create(id: -1, user: user)

    assert_queries(1){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_queries(0){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_cache('active_model_cachers_User_at_posts_4' => [post])

    assert_queries(1){ post.destroy }
    assert_cache({})

    assert_queries(1){ assert_equal [], User.cacher_at(user.id).posts }
    assert_queries(0){ assert_equal [], User.cacher_at(user.id).posts }
    assert_cache('active_model_cachers_User_at_posts_4' => [])
  ensure
    post.delete
  end

  # ----------------------------------------------------------------
  # ● Delete
  # ----------------------------------------------------------------
  def test_delete
    user = User.find_by(name: 'John4')
    post = Post.create(id: -1, user: user)

    assert_queries(1){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_queries(0){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_cache('active_model_cachers_User_at_posts_4' => [post])

    assert_queries(1){ post.delete }
    assert_cache({})

    assert_queries(1){ assert_equal [], User.cacher_at(user.id).posts }
    assert_queries(0){ assert_equal [], User.cacher_at(user.id).posts }
    assert_cache('active_model_cachers_User_at_posts_4' => [])
  ensure
    post.delete
  end

  def test_delete_without_model
    user = User.find_by(name: 'John4')
    post = Post.create(id: -1, user: user)

    assert_queries(1){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_queries(0){ assert_equal [post], User.cacher_at(user.id).posts }
    assert_cache('active_model_cachers_User_at_posts_4' => [post])

    assert_queries(2){ Post.delete(-1) } # 1: select post.user_id to clean cache on user.posts. 2: delete post.
    assert_cache({})

    assert_queries(1){ assert_equal [], User.cacher_at(user.id).posts }
    assert_queries(0){ assert_equal [], User.cacher_at(user.id).posts }
    assert_cache('active_model_cachers_User_at_posts_4' => [])
  ensure
    post.delete
  end
end
