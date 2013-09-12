guard :rspec do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^actions/(.+)\.rb$}) { |m| "spec/actions/#{m[1]}_spec.rb" }
  watch(%r{^models/(.+)\.rb$}) { |m| "spec/models/#{m[1]}_spec.rb" }
  watch(%r{^models/classes/(.+)\.rb$}) { |m| "spec/models/classes/#{m[1]}_spec.rb" }
  watch(%r{^migrations/(.+)\.rb$}) { 'spec' }
end
