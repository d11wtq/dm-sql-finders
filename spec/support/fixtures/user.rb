class User
  include DataMapper::Resource

  property :id,       Serial
  property :username, String

  has n, :posts
end
