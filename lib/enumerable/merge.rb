module Enumerable
  # The right enumerator is accessed first
  def merge_right(other_enum, id_method = nil)
    Enumerator.new do |yielder|
      yielded_ids = []

      other_enum.each do |x|
        id = id_method ? x.send(id_method) : x
        yielded_ids << id
        yielder << x
      end

      self.each do |x|
        id = id_method ? x.send(id_method) : x
        yielder << x unless yielded_ids.include? id
      end
    end
  end

  # The left enumerator is accessed first
  def merge_left(other_enum, id_method = nil)
    Enumerator.new do |yielder|
      yielded_ids = []

      self.each do |x|
        id = id_method ? x.send(id_method) : x
        yielded_ids << id
        yielder << x
      end

      other_enum.each do |x|
        id = id_method ? x.send(id_method) : x
        yielder << x unless yielded_ids.include? id
      end
    end
  end
end