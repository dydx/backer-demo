# This is a fairly standard repository. Depending on the adapter
# you are using, you would inherit differently; e.g Backer::Sqlite::Base

class EventMemoryRepository < Backer::Memory::Base
  model_class Event
end
