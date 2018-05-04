require 'base_test'

class CacheSelfTest < BaseTest
  def test_basic_usage

    assert_queries(1){ assert_equal 4, User.cacher_at(nil).count }
    assert_cache('active_model_cachers_User_at_count' => 4)

    assert_queries(0){ assert_equal 4, User.cacher_at(nil).count }
    assert_cache('active_model_cachers_User_at_count' => 4)
  end

  def test_create
    user = nil
    
    assert_queries(1){ assert_equal 4, User.cacher_at(nil).count }
    assert_queries(0){ assert_equal 4, User.cacher_at(nil).count }
    assert_cache('active_model_cachers_User_at_count' => 4)

    user = User.create(id: -1)
    assert_cache({})

    assert_queries(1){ assert_equal 5, User.cacher_at(nil).count }
    assert_queries(0){ assert_equal 5, User.cacher_at(nil).count }
    assert_cache('active_model_cachers_User_at_count' => 5)
  ensure
    user.destroy if user
  end

  def test_destroy
    user = User.create

    assert_queries(1){ assert_equal 5, User.cacher_at(nil).count }
    assert_queries(0){ assert_equal 5, User.cacher_at(nil).count }
    assert_cache("active_model_cachers_User_at_count" => 5)

    user.destroy
    assert_cache({})

    assert_queries(1){ assert_equal 4, User.cacher_at(nil).count }
    assert_queries(0){ assert_equal 4, User.cacher_at(nil).count }
    assert_cache('active_model_cachers_User_at_count' => 4)
  ensure
    user.destroy
  end

  def test_delete
    user = User.create

    assert_queries(1){ assert_equal 5, User.cacher_at(nil).count }
    assert_queries(0){ assert_equal 5, User.cacher_at(nil).count }
    assert_cache("active_model_cachers_User_at_count" => 5)

    user.delete
    assert_cache({})

    assert_queries(1){ assert_equal 4, User.cacher_at(nil).count }
    assert_queries(0){ assert_equal 4, User.cacher_at(nil).count }
    assert_cache('active_model_cachers_User_at_count' => 4)
  ensure
    user.destroy
  end
end
