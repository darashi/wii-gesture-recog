class Classifier
  def initialize(path)
    @path = path
    @templates = nil
  end
  def load_templates
    @templates = {}
    Dir[File.join(@path, "*")].each do |path|
      seq = []
      File.read(path).each do |v|
        a = v.split
        seq << [a[1].to_i, a[2].to_i, a[3].to_i] # 時刻情報は捨てる
      end
      @templates[File.basename(path)] = seq
    end
  end
  def classify(sequence)
    load_templates

    sequence_without_time = sequence.map{|x| x[1,3]}
    results = {}
    max = argmax = nil
    @templates.sort.each do |key, seq|
      dist = Classifier.dtw(sequence_without_time, seq)
      if max.nil? || dist <= max
        max = dist
        argmax = key
      end
      results[key] = dist
    end
    results.sort_by {|key, d| d}.each do |key, d|
      p [key, d]
    end
    p [:class, argmax]

    argmax
  end
  private
  def self.dtw(x, y)
    n = x.size
    m = y.size
    d = x.first.size
    f = []
    (n+1).times do
      f << Array.new(m+1)
    end
    f[0][0] = 0
    for i in 1..n
      for j in 1..m
        fs = [(f[i][j-1] rescue nil), (f[i-1][j] rescue nil), (f[i-1][j-1] rescue nil)]
        t = 0
        for k in 0...d
          t += (x[i-1][k] - y[j-1][k])**2
        end
        dij = Math.sqrt(t)
        #      dij = (x[i-1]-y[j-1]).abs
        f[i][j] = dij + fs.compact.min
      end
    end
    f[n][m]
  end
end
