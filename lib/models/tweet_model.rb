# This is about the most basic "model" you can make

Tweet = Struct.new(:id, :content, :deleted)
Event = Struct.new(:id, :name, :attributes)
