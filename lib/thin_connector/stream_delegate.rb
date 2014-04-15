module ThinConnector
  module StreamDelegate
    def method_missing(m, *args, &block)
      if @stream.respond_to?(m)
        @stream.send(m, *args, &block)
      else
        super(m, *args, &block)
      end
    end
  end
end