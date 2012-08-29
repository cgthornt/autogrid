module Autogrid
  module Util
    
    def self.optionize(default_options, options_proc, *passed_options)
      passed_options = [passed_options] unless passed_options.is_a?(Array)
      puts passed_options.inspect
      passed = passed_options.extract_options!
      passed_options.each{ |p| passed[p] = true }
      passed = default_options.merge(passed)
      passed.each do |k,v|
        if v.is_a?(Hash)
          passed[k] = optionize((default_options[k] ||= {}), (options_proc[k] ||= {}), v)
        end
        passed[k] = v.call if v.is_a?(Proc)
        options_proc[k].call(v,passed) if(options_proc.is_a?(Hash) and options_proc.key?(k) and options_proc[k].is_a?(Proc))
      end
      return passed
    end
    
    def self.nested_send(obj, str)
      return obj if str.blank?
      return obj.send str unless str.is_a? String
      sp = str.split '.'
      last = obj
      sp.collect{|x| last = last.send x.to_sym }
      return last
    end
    
    def sqlize(str)
      vals = str.split(/\./)
      if vals.size == 1
        return "`#{vals[0]}`"
      else
        return "`#{vals[vals.size - 2].tableize}`.`#{vals.last}`"
      end
    end
    
  end
end
