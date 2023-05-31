# Core class extensions
# Copyright (c) M.J.N. Corino, The Netherlands

class ::Array

  def resize(sz, obj=nil, &block)
    if sz > self.size
      if block
        self.fill(sz-1, 0, &block)
      else
        self.fill(obj, sz-1, 0)
      end
    elsif sz < self.size
      self.slice!(0, sz)
    end
    self
  end

end
