## Data and Methods

This tool was developed by the SNSF as a prototype. It is a first step towards the goal of Dimensions offering OA reports as part of their free and openly available services.
The workflow is as follows:

*	Dimensions is used to procure a list of articles published from 2015 onwards  (other publication formats are currently not considered, see limitations)
*	Unpaywall data is used to gather open access specific metadata of every article on the list
* Results are evaluated according to the SNSF’s definitions of open access
*	A report is generated, providing an overview and a complete list of all articles and their individual open-access status


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
