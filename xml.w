@*XML.
gjobread.c : a small test program for gnome jobs XML format |Daniel.Veillard@w3.org|
@c
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>
@
This example should compile and run indifferently with libxml-1.8.8 +
and libxml2-2.1.0 +
Check the COMPAT comments below

COMPAT using xml-config --cflags to get the include path this will
work with both 
@f xmlChar      int
@f xmlDocPtr    int
@f xmlNsPtr     int
@f xmlNodePtr   int
@c
#include <libxml/xmlmemory.h>
#include <libxml/parser.h>

#define DEBUG(x) printf(x)
@
A person record
an |xmlChar *| is really an UTF8 encoded char string (0 terminated)
@c
typedef struct person {
    xmlChar *name;
    xmlChar *email;
    xmlChar *company;
    xmlChar *organisation;
    xmlChar *smail;
    xmlChar *webPage;
    xmlChar *phone;
} person, *personPtr;
@
And the code needed to parse it
@c
static personPtr parsePerson(xmlDocPtr doc, xmlNsPtr ns, xmlNodePtr cur) {
    personPtr ret = NULL;

DEBUG("parsePerson\n");
    /*
     * allocate the struct
     */
    ret = (personPtr) malloc(sizeof(person));
    if (ret == NULL) {
        fprintf(stderr,"out of memory\n");
    return(NULL);
    }
    memset(ret, 0, sizeof(person));

    /* We don't care what the top level element name is */
    /* COMPAT xmlChildrenNode is a macro unifying libxml1 and libxml2 names */
    cur = cur->xmlChildrenNode;
    while (cur != NULL) {
        if ((!xmlStrcmp(cur->name, (const xmlChar *)"Person")) &&
        (cur->ns == ns))
        ret->name = xmlNodeListGetString(doc, cur->xmlChildrenNode, 1);
        if ((!xmlStrcmp(cur->name, (const xmlChar *)"Email")) &&
        (cur->ns == ns))
        ret->email = xmlNodeListGetString(doc, cur->xmlChildrenNode, 1);
    cur = cur->next;
    }

    return(ret);
}
@
and to print it
@c
static void printPerson(personPtr cur) {
    if (cur == NULL) return;
    printf("------ Person\n");
    if (cur->name) printf(" name: %s\n", cur->name);
    if (cur->email) printf("    email: %s\n", cur->email);
    if (cur->company) printf("  company: %s\n", cur->company);
    if (cur->organisation) printf(" organisation: %s\n", cur->organisation);
    if (cur->smail) printf("    smail: %s\n", cur->smail);
    if (cur->webPage) printf("  Web: %s\n", cur->webPage);
    if (cur->phone) printf("    phone: %s\n", cur->phone);
    printf("------\n");
}
@
a Description for a Job
@c
typedef struct job {
    xmlChar *projectID;
    xmlChar *application;
    xmlChar *category;
    personPtr contact;
    int nbDevelopers;
    personPtr developers[100]; /* using dynamic alloc is left as an exercise */
} job, *jobPtr;
@
And the code needed to parse it
@c
static jobPtr parseJob(xmlDocPtr doc, xmlNsPtr ns, xmlNodePtr cur) {
    jobPtr ret = NULL;

DEBUG("parseJob\n");
    /*
     * allocate the struct
     */
    ret = (jobPtr) malloc(sizeof(job));
    if (ret == NULL) {
        fprintf(stderr,"out of memory\n");
    return(NULL);
    }
    memset(ret, 0, sizeof(job));

    /* We don't care what the top level element name is */
    cur = cur->xmlChildrenNode;
    while (cur != NULL) {
        
        if ((!xmlStrcmp(cur->name, (const xmlChar *) "Project")) &&
        (cur->ns == ns)) {
        ret->projectID = xmlGetProp(cur, (const xmlChar *) "ID");
        if (ret->projectID == NULL) {
        fprintf(stderr, "Project has no ID\n");
        }
    }
    if ((!xmlStrcmp(cur->name, (const xmlChar *) "Application")) &&
        (cur->ns == ns))
    ret->application = 
    xmlNodeListGetString(doc, cur->xmlChildrenNode, 1);
    if ((!xmlStrcmp(cur->name, (const xmlChar *) "Category")) &&
    (cur->ns == ns))
    ret->category =
    xmlNodeListGetString(doc, cur->xmlChildrenNode, 1);
    if ((!xmlStrcmp(cur->name, (const xmlChar *) "Contact")) &&
    (cur->ns == ns))
    ret->contact = parsePerson(doc, ns, cur);
    cur = cur->next;
    }

    return(ret);
}
@
and to print it
@c
static void printJob(jobPtr cur) {
    int i;

    if (cur == NULL) return;
    printf("=======  Job\n");
    if (cur->projectID != NULL) printf("projectID: %s\n", cur->projectID);
    if (cur->application != NULL) printf("application: %s\n", cur->application);
    if (cur->category != NULL) printf("category: %s\n", cur->category);
    if (cur->contact != NULL) printPerson(cur->contact);
    printf("%d developers\n", cur->nbDevelopers);

    for (i = 0;i < cur->nbDevelopers;i++) printPerson(cur->developers[i]);
    printf("======= \n");
}
@
A pool of Gnome Jobs
@c
typedef struct gjob {
    int nbJobs;
    jobPtr jobs[500]; /* using dynamic alloc is left as an exercise */
} gJob, *gJobPtr;

@ handle root element as boolean function returning the value in the first parameter.
This way one can cascade the function into a sequence of |&&| symbols.
@c
static bool readRoot(xmlNodePtr*cur, xmlDocPtr doc){
    *cur = xmlDocGetRootElement(doc);
    if (*cur == NULL) {
        fprintf(stderr,"empty document\n");
        xmlFreeDoc(doc);
        return false;
    }
    else
        return true;
}
@
@c
static bool checkNamespace(xmlNsPtr *ns, xmlDocPtr doc,xmlNodePtr cur){
    *ns = xmlSearchNsByHref(doc, cur,
            (const xmlChar *) "http://www.gnome.org/some-location");
    if (*ns == NULL) {
        fprintf(stderr,
                "document of the wrong type, GJob Namespace not found\n");
        xmlFreeDoc(doc);
        return false;
    }
    else 
        return true;
}
@
@c
static gJobPtr parseGjobFile(char *filename) {
    xmlDocPtr doc;
    gJobPtr ret;
    jobPtr curjob;
    xmlNsPtr ns;
    xmlNodePtr cur;


    doc = xmlParseFile(filename);     /* build an XML tree from a the file */
    if (doc == NULL) return(NULL);

    
    if(readRoot(&cur, doc)
            && checkNamespace(&ns, doc, cur)){ /* Check the document is of the right kind */
        if (xmlStrcmp(cur->name, (const xmlChar *) "Helping")) {
            fprintf(stderr,"document of the wrong type, root node != Helping");
        xmlFreeDoc(doc);
        return(NULL);
        }

        
        ret = (gJobPtr) malloc(sizeof(gJob)); /* Allocate the structure to be returned.  */
        if (ret == NULL) {
            fprintf(stderr,"out of memory\n");
        xmlFreeDoc(doc);
        return(NULL);
        }
        memset(ret, 0, sizeof(gJob));

        /*
        * Now, walk the tree.
        */
        /* First level we expect just Jobs */
        cur = cur->xmlChildrenNode;
        while ( cur && xmlIsBlankNode ( cur ) ) {
        cur = cur -> next;
        }
        if ( cur == 0 ) {
        xmlFreeDoc(doc);
        free(ret);
        return ( NULL );
        }
        if ((xmlStrcmp(cur->name, (const xmlChar *) "Jobs")) || (cur->ns != ns)) {
            fprintf(stderr,"document of the wrong type, was '%s', Jobs expected",
            cur->name);
        fprintf(stderr,"xmlDocDump follows\n");
        xmlDocDump ( stderr, doc );
        fprintf(stderr,"xmlDocDump finished\n");
        xmlFreeDoc(doc);
        free(ret);
        return(NULL);
        }

        /* Second level is a list of Job, but be laxist */
        cur = cur->xmlChildrenNode;
        while (cur != NULL) {
            if ((!xmlStrcmp(cur->name, (const xmlChar *) "Job")) &&
            (cur->ns == ns)) {
            curjob = parseJob(doc, ns, cur);
            if (curjob != NULL)
                ret->jobs[ret->nbJobs++] = curjob;
                if (ret->nbJobs >= 500) break;
        }
        cur = cur->next;
        }

        return(ret);
    }
    else
        return NULL;
}
@
@c
static void handleGjob(gJobPtr cur) {
    int i;

    /*
     * Do whatever you want and free the structure.
     */
    printf("%d Jobs registered\n", cur->nbJobs);
    for (i = 0; i < cur->nbJobs; i++) printJob(cur->jobs[i]);
}
@
@c
int main(int argc, char **argv) {
    int i;
    gJobPtr cur;

    /* COMPAT: Do not generate nodes for formatting spaces */
    LIBXML_TEST_VERSION
    xmlKeepBlanksDefault(0);

    for (i = 1; i < argc ; i++) {
    cur = parseGjobFile(argv[i]);
    if ( cur )
      handleGjob(cur);
    else
      fprintf( stderr, "Error parsing file '%s'\n", argv[i]);

    }

    /* Clean up everything else before quitting. */
    xmlCleanupParser();

    return(0);
}


@ dummy file

@(dummy.c@>=
// dummy file

#define XPUBLIC

XPUBLIC void dummy(){

}

@*Index.