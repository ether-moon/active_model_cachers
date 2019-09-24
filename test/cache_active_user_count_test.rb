# frozen_string_literal: true
require 'base_test'

class CacheActiveUserCountTest < BaseTest
  def test_basic_usage
    assert_queries(1){ assert_equal 2, User.cacher.active_count }
    assert_cache('active_model_cachers_User_at_active_count' => 2)

    assert_queries(0){ assert_equal 2, User.cacher.active_count }
    assert_cache('active_model_cachers_User_at_active_count' => 2)
  end

  # ----------------------------------------------------------------
  # ● Create
  # ----------------------------------------------------------------
  def test_create
    user = nil

    assert_queries(1){ assert_equal 2, User.cacher.active_count }
    assert_queries(0){ assert_equal 2, User.cacher.active_count }
    assert_cache('active_model_cachers_User_at_active_count' => 2)

    assert_queries(1){ user = User.create(id: -1, last_login_at: Time.now) }
    assert_cache({})

    assert_queries(1){ assert_equal 3, User.cacher.active_count }
    assert_queries(0){ assert_equal 3, User.cacher.active_count }
    assert_cache('active_model_cachers_User_at_active_count' => 3)
  ensure
    user.destroy if user
  end

  # ----------------------------------------------------------------
  # ● Clean
  # ----------------------------------------------------------------
  def test_clean
    Rails.cache.write('active_model_cachers_User_at_active_count', 2)
    assert_cache('active_model_cachers_User_at_active_count' => 2)

    assert_queries(0){ User.cacher.clean_active_count }
    assert_cache({})
  end

  def test_clean2
    Rails.cache.write('active_model_cachers_User_at_active_count', 2)
    assert_cache('active_model_cachers_User_at_active_count' => 2)

    assert_queries(0){ User.cacher.clean(:active_count) }
    assert_cache({})
  end

  # ----------------------------------------------------------------
  # ● Update
  # ----------------------------------------------------------------
  def test_update_nothing
    user = User.find_by(name: 'John2')

    assert_queries(1){ assert_equal 2, User.cacher.active_count }
    assert_queries(0){ assert_equal 2, User.cacher.active_count }
    assert_cache('active_model_cachers_User_at_active_count' => 2)

    assert_queries(0){ user.save }
    assert_cache('active_model_cachers_User_at_active_count' => 2)

    assert_queries(0){ assert_equal 2, User.cacher.active_count }
    assert_cache('active_model_cachers_User_at_active_count' => 2)
  end

  def test_update_unrelated_column
    user = User.find_by(name: 'John4')

    assert_queries(1){ assert_equal 2, User.cacher.active_count }
    assert_queries(0){ assert_equal 2, User.cacher.active_count }
    assert_cache('active_model_cachers_User_at_active_count' => 2)

    assert_queries(1){ user.update_attributes(name: '??') }
    assert_cache('active_model_cachers_User_at_active_count' => 2)

    assert_queries(0){ assert_equal 2, User.cacher.active_count }
    assert_cache('active_model_cachers_User_at_active_count' => 2)
  ensure
    user.update(name: 'John4')
  end

  def test_update
    user = User.find_by(name: 'John4')

    assert_queries(1){ assert_equal 2, User.cacher.active_count }
    assert_queries(0){ assert_equal 2, User.cacher.active_count }
    assert_cache('active_model_cachers_User_at_active_count' => 2)

    assert_queries(1){ user.update(last_login_at: Time.now) }
    assert_cache({})

    assert_queries(1){ assert_equal 3, User.cacher.active_count }
    assert_queries(0){ assert_equal 3, User.cacher.active_count }
    assert_cache('active_model_cachers_User_at_active_count' => 3)
  ensure
    user.update(last_login_at: nil)
  end

  # ----------------------------------------------------------------
  # ● Destroy
  # ----------------------------------------------------------------
  def test_destroy
    user = User.create(last_login_at: Time.now)

    assert_queries(1){ assert_equal 3, User.cacher.active_count }
    assert_queries(0){ assert_equal 3, User.cacher.active_count }
    assert_cache("active_model_cachers_User_at_active_count" => 3)

    assert_queries(user_destroy_dependents_count){ user.destroy }
    assert_cache({})

    assert_queries(1){ assert_equal 2, User.cacher.active_count }
    assert_queries(0){ assert_equal 2, User.cacher.active_count }
    assert_cache('active_model_cachers_User_at_active_count' => 2)
  ensure
    user.destroy
  end

  # ----------------------------------------------------------------
  # ● Delete
  # ----------------------------------------------------------------
  def test_delete
    user = User.create(last_login_at: Time.now)

    assert_queries(1){ assert_equal 3, User.cacher.active_count }
    assert_queries(0){ assert_equal 3, User.cacher.active_count }
    assert_cache("active_model_cachers_User_at_active_count" => 3)

    assert_queries(1){ user.delete }
    assert_cache({})

    assert_queries(1){ assert_equal 2, User.cacher.active_count }
    assert_queries(0){ assert_equal 2, User.cacher.active_count }
    assert_cache('active_model_cachers_User_at_active_count' => 2)
  ensure
    user.destroy
  end

  def test_destroyed_by_dependent_delete
    # TODO
  end
end
