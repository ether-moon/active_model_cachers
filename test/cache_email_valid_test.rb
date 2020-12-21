# frozen_string_literal: true
require 'base_test'

class CacheEmailValidTest < BaseTest
  def test_basic_usage
    assert_queries(1){ assert_equal true, User.cacher_at('john2@example.com').email_valid? }
    assert_queries(0){ assert_equal true, User.cacher_at('john2@example.com').email_valid? }
    assert_cache('active_model_cachers_User_at_email_valid?_john2@example.com' => true)
  end

  def test_basic_usage_of_instance_cacher
    user = User.find_by(name: 'John2')

    assert_queries(1){ assert_equal true, user.cacher.email_valid? }
    assert_queries(0){ assert_equal true, user.cacher.email_valid? }
    assert_cache('active_model_cachers_User_at_email_valid?_john2@example.com' => true)
  end

  def test_instance_cacher_without_association_cache
    user1 = User.find_by(name: 'John2')
    user2 = User.find_by(name: 'John2')

    assert_queries(1){ assert_equal true, user1.cacher.email_valid? }
    assert_queries(0){ assert_equal true, user2.cacher.email_valid? }
    assert_cache('active_model_cachers_User_at_email_valid?_john2@example.com' => true)
  end

  # ----------------------------------------------------------------
  # ● Create
  # ----------------------------------------------------------------
  def test_create
    user = nil

    assert_queries(1){ assert_equal false, User.cacher_at('fake@fake.com').email_valid? }
    assert_queries(0){ assert_equal false, User.cacher_at('fake@fake.com').email_valid? }
    assert_cache('active_model_cachers_User_at_email_valid?_fake@fake.com' => ActiveModelCachers::FalseObject)

    assert_queries(1){ user = User.create(id: -1, email: 'fake@fake.com') }
    assert_cache('active_model_cachers_User_at_email_valid?_fake@fake.com' => ActiveModelCachers::FalseObject)

    assert_queries(0){ assert_equal false, user.cacher.email_valid? }
    assert_cache('active_model_cachers_User_at_email_valid?_fake@fake.com' => ActiveModelCachers::FalseObject)
  ensure
    user.delete if user
  end

  # ----------------------------------------------------------------
  # ● Clean
  # ----------------------------------------------------------------
  def test_clean
    Rails.cache.write('active_model_cachers_User_at_email_valid?_john2@example.com', true)
    assert_cache('active_model_cachers_User_at_email_valid?_john2@example.com' => true)

    assert_queries(0){ User.cacher_at('john2@example.com').clean_email_valid? }
    assert_cache({})
  end

  def test_clean2
    Rails.cache.write('active_model_cachers_User_at_email_valid?_john2@example.com', true)
    assert_cache('active_model_cachers_User_at_email_valid?_john2@example.com' => true)

    assert_queries(0){ User.cacher_at('john2@example.com').clean(:email_valid?) }
    assert_cache({})
  end

  def test_clean_in_instance_cacher
    user = User.find_by(name: 'John2')

    Rails.cache.write('active_model_cachers_User_at_email_valid?_john2@example.com', true)
    assert_cache('active_model_cachers_User_at_email_valid?_john2@example.com' => true)

    assert_queries(0){ user.cacher.clean_email_valid? }
    assert_cache({})
  end

  def test_clean_by_primary_key
    Rails.cache.write('active_model_cachers_User_at_email_valid?_john2@example.com', true)
    assert_cache('active_model_cachers_User_at_email_valid?_john2@example.com' => true)

    assert_queries(0){ User.cacher_at('john2@example.com').clean(:email_valid?) }

    assert_cache({})
  end

  # ----------------------------------------------------------------
  # ● Update
  # ----------------------------------------------------------------
  def test_update_nothing
    user = User.find_by(name: 'John2')

    assert_queries(1){ assert_equal true, user.cacher.email_valid? }
    assert_queries(0){ assert_equal true, user.cacher.email_valid? }
    assert_cache('active_model_cachers_User_at_email_valid?_john2@example.com' => true)

    assert_queries(0){ user.save }
    assert_cache('active_model_cachers_User_at_email_valid?_john2@example.com' => true)

    assert_queries(0){ assert_equal true, user.cacher.email_valid? }
    assert_cache('active_model_cachers_User_at_email_valid?_john2@example.com' => true)
  end

  def test_update
    user = User.find_by(name: 'John2')

    assert_queries(1){ assert_equal true, user.cacher.email_valid? }
    assert_queries(0){ assert_equal true, user.cacher.email_valid? }
    assert_cache('active_model_cachers_User_at_email_valid?_john2@example.com' => true)

    assert_queries(1){ user.update(email: 'fake@fake.com') }
    assert_cache('active_model_cachers_User_at_email_valid?_john2@example.com' => true)

    assert_queries(1){ assert_equal false, user.cacher.email_valid? }
    assert_queries(0){ assert_equal false, user.cacher.email_valid? }
    assert_cache(
      'active_model_cachers_User_at_email_valid?_john2@example.com' => true,
      'active_model_cachers_User_at_email_valid?_fake@fake.com' => ActiveModelCachers::FalseObject,
    )
  ensure
    user.update(email: 'john2@example.com')
  end

  # email_valid2
  def test_update_any_column_2
    user = User.find_by(name: 'John2')

    assert_queries(1){ assert_equal true, user.cacher.email_valid2? }
    assert_queries(0){ assert_equal true, user.cacher.email_valid2? }
    assert_cache('active_model_cachers_User_at_email_valid2?_john2@example.com' => true)

    assert_queries(1){ user.update(last_login_at: Time.now) }
    assert_cache({})

    assert_queries(1){ assert_equal true, user.cacher.email_valid2? }
    assert_queries(0){ assert_equal true, user.cacher.email_valid2? }
    assert_cache( 'active_model_cachers_User_at_email_valid2?_john2@example.com' => true)
  end

  # email_valid3
  def test_update_3
    user = User.find_by(name: 'John2')

    assert_queries(1){ assert_equal true, user.cacher.email_valid3? }
    assert_queries(0){ assert_equal true, user.cacher.email_valid3? }
    assert_cache('active_model_cachers_User_at_email_valid3?_john2@example.com' => true)

    assert_queries(1){ user.update(name: 'John5') }
    assert_cache({})

    assert_queries(1){ assert_equal true, user.cacher.email_valid3? }
    assert_queries(0){ assert_equal true, user.cacher.email_valid3? }
    assert_cache( 'active_model_cachers_User_at_email_valid3?_john2@example.com' => true)
  ensure
    user.update(name: 'John2')
  end

  def test_update_unrelated_column_3
    user = User.find_by(name: 'John2')

    assert_queries(1){ assert_equal true, user.cacher.email_valid3? }
    assert_queries(0){ assert_equal true, user.cacher.email_valid3? }
    assert_cache('active_model_cachers_User_at_email_valid3?_john2@example.com' => true)

    assert_queries(1){ user.update(last_login_at: Time.now) }
    assert_cache('active_model_cachers_User_at_email_valid3?_john2@example.com' => true)

    assert_queries(0){ assert_equal true, user.cacher.email_valid3? }
    assert_cache( 'active_model_cachers_User_at_email_valid3?_john2@example.com' => true)
  end

  # ----------------------------------------------------------------
  # ● Destroy
  # ----------------------------------------------------------------
  def test_destroy
    user = User.create(id: -1, email: 'fake@fake.com')

    assert_queries(1){ assert_equal false, User.cacher_at('fake@fake.com').email_valid? }
    assert_queries(0){ assert_equal false, User.cacher_at('fake@fake.com').email_valid? }
    assert_cache('active_model_cachers_User_at_email_valid?_fake@fake.com' => ActiveModelCachers::FalseObject)

    assert_queries(user_destroy_dependents_count){ user.destroy }
    assert_cache('active_model_cachers_User_at_email_valid?_fake@fake.com' => ActiveModelCachers::FalseObject)
  ensure
    user.delete
  end
end
