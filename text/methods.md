## Data and Methods

__Data__

The following data sources are used:

*	[__Dimensions__](https://app.dimensions.ai): currently among the most comprehensive sources available to search for publications by individual researchers.

*	[__Unpaywall__](https://unpaywall.org): the largest available database of identified legal OA versions of scientific articles. It is used to gather additional metadata on the publishing status of the articles in question.


__Methods__

The list of articles obtained through Dimensions is enriched with the following metadata from Unpaywall for every article: 

* `is_oa`: Whether any OA version of the article was found
* `journal_is_oa`: Whether the article was published in a completely OA journal
* `host_type`: Whether the identified OA version of an article is provided by the publisher or a repository
* `version`: Whether the identified OA version of an article is the submitted version (not peer-reviewed), accepted version (peer-reviewed manuscript) or published version (peer-reviewed version of record)

To assign open-access categories in accordance with SNSF regulations, the following definitions are used:

* __Gold__: Openly available, journal is fully OA, hosted by the publisher
* __Green__: Openly available, hosted on a repository, either as accepted or published version
* __Hybrid__: Openly available, journal not fully OA, hosted by the publisher
* __Other OA__: Openly available but does not meet requirements for other categories
* __Closed__: No openly available version found by Unpaywall
