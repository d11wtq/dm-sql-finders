class User
  include DataMapper::Resource

  property :id,       Serial
  property :username, String
  property :role,     String

  has n, :posts
end
