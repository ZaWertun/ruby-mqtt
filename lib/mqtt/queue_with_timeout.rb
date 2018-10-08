class QueueWithTimeout
  def initialize
    @mutex    = Mutex.new
    @queue    = []
    @received = ConditionVariable.new
  end

  def push(x)
    @mutex.synchronize do
      @queue.push(x)
      @received.signal
    end
  end

  alias << push

  def pop(non_block = false)
    pop_with_timeout(non_block ? 0 : nil)
  end

  def size
    @mutex.synchronize { @queue.size }
  end

  alias length size

  def empty?
    @mutex.synchronize { @queue.empty? }
  end

  def pop_with_timeout(timeout = nil)
    @mutex.synchronize do
      if timeout.nil?
        @received.wait(@mutex) while @queue.empty?
      elsif @queue.empty? && timeout != 0
        timeout_time = timeout + Time.now.to_f
        while @queue.empty? && (remaining = timeout_time - Time.now.to_f) > 0
          @received.wait(@mutex, remaining)
        end
      end
      return nil if @queue.empty?
      @queue.shift
    end
  end
end
