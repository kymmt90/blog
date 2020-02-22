require 'fileutils'
require 'time'

filename_and_last_commit_datetime = {}

Dir.glob('*.md').each do |md|
  filename_and_last_commit_datetime[md] = Time.parse(`git log -1 --format=%cd #{md}`)
end

filename_and_last_commit_datetime.each do |filename, datetime|
  year = datetime.year
  FileUtils.move filename, "#{year}/#{filename}"
end
