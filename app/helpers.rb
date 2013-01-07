helpers do
  def total(keys)
    keys.map { |k| k.balance }.reduce { |a, b| a + b }
  end
end
