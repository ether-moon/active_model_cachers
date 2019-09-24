# frozen_string_literal: true
require 'base_test'

class CacheSelfByOtherColumnTest < BaseTest
  def test_basic_usage
    profile = User.find_by(name: 'John2').profile

    assert_queries(1){ assert_equal 10, Profile.cacher.find_by(token: 'tt9wav').point }
    assert_queries(0){ assert_equal 10, Profile.cacher.find_by(token: 'tt9wav').point }
    assert_cache('active_model_cachers_Profile_by_token_tt9wav' => profile)

    assert_queries(0){ assert_equal 10, Profile.cacher.find_by(token: 'tt9wav').point }
    assert_cache('active_model_cachers_Profile_by_token_tt9wav' => profile)
  end

  # ----------------------------------------------------------------
  # ● Create
  # ----------------------------------------------------------------
  def test_create
    profile = nil

    assert_queries(1){ assert_nil Profile.cacher.find_by(token: 'a') }
    assert_queries(0){ assert_nil Profile.cacher.find_by(token: 'a') }
    assert_cache('active_model_cachers_Profile_by_token_a' => ActiveModelCachers::NilObject)

    assert_queries(1){ profile = Profile.create(id: -1, point: 3, token: 'a') }
    assert_cache({})

    assert_queries(1){ assert_equal 3, Profile.cacher.find_by(token: 'a').point }
    assert_queries(0){ assert_equal 3, Profile.cacher.find_by(token: 'a').point }
    assert_cache('active_model_cachers_Profile_by_token_a' => profile)
  ensure
    profile.destroy if profile
  end

  # ----------------------------------------------------------------
  # ● Clean
  # ----------------------------------------------------------------
  def test_clean
    profile = User.find_by(name: 'John2').profile

    Rails.cache.write('active_model_cachers_Profile_by_token_tt9wav', profile)
    assert_cache('active_model_cachers_Profile_by_token_tt9wav' => profile)

    assert_queries(0){ Profile.cacher.clean_by(token: 'tt9wav') }
    assert_cache({})
  end

  def test_clean2
    profile = User.find_by(name: 'John2').profile

    Rails.cache.write('active_model_cachers_Profile_by_token_tt9wav', profile)
    assert_cache('active_model_cachers_Profile_by_token_tt9wav' => profile)

    assert_queries(0){ Profile.cacher.clean_by(token: 'tt9wav') }
    assert_cache({})
  end

  # ----------------------------------------------------------------
  # ● Update
  # ----------------------------------------------------------------
  def test_update_nothing
    profile = User.find_by(name: 'John2').profile

    assert_queries(1){ assert_equal 10, Profile.cacher.find_by(token: 'tt9wav').point }
    assert_queries(0){ assert_equal 10, Profile.cacher.find_by(token: 'tt9wav').point }
    assert_cache('active_model_cachers_Profile_by_token_tt9wav' => profile)

    assert_queries(0){ profile.save }
    assert_cache('active_model_cachers_Profile_by_token_tt9wav' => profile)

    assert_queries(0){ assert_equal 10, Profile.cacher.find_by(token: 'tt9wav').point }
    assert_cache('active_model_cachers_Profile_by_token_tt9wav' => profile)
  end

  def test_update
    profile = User.find_by(name: 'John2').profile

    assert_queries(1){ assert_equal 10, Profile.cacher.find_by(token: 'tt9wav').point }
    assert_queries(0){ assert_equal 10, Profile.cacher.find_by(token: 'tt9wav').point }
    assert_cache('active_model_cachers_Profile_by_token_tt9wav' => profile)

    assert_queries(1){ profile.update(point: 12) }
    assert_cache({})

    assert_queries(1){ assert_equal 12, Profile.cacher.find_by(token: 'tt9wav').point }
    assert_queries(0){ assert_equal 12, Profile.cacher.find_by(token: 'tt9wav').point }
    assert_cache('active_model_cachers_Profile_by_token_tt9wav' => profile)
  ensure
    profile.update(point: 10)
  end

  # ----------------------------------------------------------------
  # ● Destroy
  # ----------------------------------------------------------------
  def test_destroy
    profile = Profile.create(point: 13, token: 'a')

    assert_queries(1){ assert_equal 13, Profile.cacher.find_by(token: 'a').point }
    assert_queries(0){ assert_equal 13, Profile.cacher.find_by(token: 'a').point }
    assert_cache('active_model_cachers_Profile_by_token_a' => profile)

    assert_queries(1){ profile.destroy }
    assert_cache({})

    assert_queries(1){ assert_nil Profile.cacher.find_by(token: 'a') }
    assert_queries(0){ assert_nil Profile.cacher.find_by(token: 'a') }
    assert_cache('active_model_cachers_Profile_by_token_a' => ActiveModelCachers::NilObject)
  ensure
    profile.destroy
  end

  # ----------------------------------------------------------------
  # ● Delete
  # ----------------------------------------------------------------
  def test_delete
    profile = Profile.create(point: 13, token: 'a')

    assert_queries(1){ assert_equal 13, Profile.cacher.find_by(token: 'a').point }
    assert_queries(0){ assert_equal 13, Profile.cacher.find_by(token: 'a').point }
    assert_cache('active_model_cachers_Profile_by_token_a' => profile)

    assert_queries(1){ profile.delete }
    assert_cache({})

    assert_queries(1){ assert_nil Profile.cacher.find_by(token: 'a') }
    assert_queries(0){ assert_nil Profile.cacher.find_by(token: 'a') }
    assert_cache('active_model_cachers_Profile_by_token_a' => ActiveModelCachers::NilObject)
  ensure
    profile.delete
  end

  def test_destroyed_by_dependent_delete
    profile = Profile.create(point: 17, token: 'a')
    user = User.create(profile: profile)

    assert_queries(1){ assert_equal 17, Profile.cacher.find_by(token: 'a').point }
    assert_queries(0){ assert_equal 17, Profile.cacher.find_by(token: 'a').point }
    assert_cache('active_model_cachers_Profile_by_token_a' => profile)

    user.destroy
    assert_cache({})

    assert_queries(1){ assert_nil Profile.cacher.find_by(token: 'a') }
    assert_queries(0){ assert_nil Profile.cacher.find_by(token: 'a') }
    assert_cache('active_model_cachers_Profile_by_token_a' => ActiveModelCachers::NilObject)
  ensure
    user.destroy
  end

  def test_delete_should_not_clean_all_models_with_same_id
    profile = Profile.create(id: -1, point: 7, token: 'a')
    difficulty = Difficulty.create(id: -1, level: 4, description: 'vary hard')

    assert_queries(1){ assert_equal 7, Profile.cacher.find_by(token: 'a').point }
    assert_queries(0){ assert_equal 7, Profile.cacher.find_by(token: 'a').point }
    assert_queries(1){ assert_equal 4, Difficulty.cacher.find_by(id: difficulty.id).level }
    assert_queries(0){ assert_equal 4, Difficulty.cacher.find_by(id: difficulty.id).level }
    assert_cache('active_model_cachers_Profile_by_token_a' => profile, 'active_model_cachers_Difficulty_-1' => difficulty)

    # delete difficulty with id = -1 should not clean the cache of profile with same id.
    difficulty.delete
    assert_cache('active_model_cachers_Profile_by_token_a' => profile)

    assert_queries(0){ assert_equal 7, Profile.cacher.find_by(token: 'a').point }
    assert_queries(1){ assert_nil Difficulty.cacher.find_by(id: difficulty.id) }
    assert_queries(0){ assert_nil Difficulty.cacher.find_by(id: difficulty.id) }
    assert_cache('active_model_cachers_Profile_by_token_a' => profile, 'active_model_cachers_Difficulty_-1' => ActiveModelCachers::NilObject)
  ensure
    profile.delete
    difficulty.delete
  end
end
