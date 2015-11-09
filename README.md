# solrwrapper

Wrap any task with a Solr instance:

```ruby
SolrWrapper.wrap do |solr|
  # Something that requires Solr
end
```

Or with Solr and a solr collection:

```ruby
SolrWrapper.wrap do |solr|
  solr.with_collection(dir: File.join(FIXTURES_DIR, "basic_configs")) do |collection_name|
  end
end
```

## Basic Options

```ruby
SolrWrapper.wrap port: 8983, verbose: true, managed: true 
```

```ruby
solr.with_collection(name: 'collection_name', dir: 'path_to_solr_configs')
```

## From the command line

```console
$ solr_wrapper -p 8983
```

## Rake tasks

SolrWrapper provides rake tasks for installing, starting and stopping solr.  To include the tasks in your Rake environment, add this to your Rakefile

```ruby
  require 'solr_wrapper/rake_task'
```

You can configure the tasks by setting SOLR_OPTIONS.  For example:

```ruby
SOLR_OPTIONS = {
    verbose: true,
    cloud: true,
    port: '8888',
    version: '5.3.1',
    instance_dir: 'solr',
    download_dir: 'tmp'
}
require 'solr_wrapper/rake_task'
```
