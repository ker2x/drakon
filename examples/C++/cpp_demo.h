/* Autogenerated with DRAKON Editor 1.11 */
#ifndef CPP_DEMO_H98321
#define CPP_DEMO_H98321

#include "StringList.h"


int main(
    int argc,
    char** argv
);

class SimpleComparer : public IStringComparer
{


public:
    virtual int Compare(
        const std::string* left,
        const std::string* right
    ) const;

};

#endif

