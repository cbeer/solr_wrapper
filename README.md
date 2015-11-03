# solrwrapper

Wrap any task with a Solr instance:

```ruby
SolrWrapper.wrap do |solr|
  # Something that requires Solr
end
```

Or with Solr and a solr collection:

```ruby
  subject.wrap do |solr|
    solr.with_collection(dir: File.join(FIXTURES_DIR, "basic_configs")) do |collection_name|
    end
  end
```

## Basic Options

```ruby
SolrWrapper.wrap port: 8983,
                 verbose: true,
                 managed: true,
                 instance_dir: '/opt/solr'
```

Options:

|Option         |                                         |
|---------------|-----------------------------------------|
| instance_dir  | Directory to store the solr index files |
| url           | ??? |
| version       | Solr version to download and install |
| port          | port to run Solr on |
| version_file  | Local path to store the currently installed version |
| download_path | Local path for storing the downloaded Solr zip file |
| md5sum        | Path/URL to MD5 checksum |
| solr_xml      | Path to Solr configuration |
| verbose       | (Boolean) |
| managed       | (Boolean) |
| ignore_md5sum | (Boolean) |
| solr_options  | (Hash) |
| env           | (Hash) |

```ruby
solr.with_collection(name: 'collection_name', dir: 'path_to_solr_confiigs')
```

## From the command line

```console
$ solr_wrapper -p 8983
```
