class Class
  def inherited(subclass) 
    if superclass.respond_to? :inherited 
      superclass.inherited(subclass) 
    end 
    @subclasses ||= [] 
    @subclasses << subclass 
  end

  def subclasses 
    @subclasses||[]
  end 
end
