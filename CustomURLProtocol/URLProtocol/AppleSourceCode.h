//
//  AppleSourceCode.h
//  CustomURLProtocol
//
//  Created by MiaoChao on 2017/12/15.
//  Copyright © 2017年 MiaoChao. All rights reserved.
//

#ifndef AppleSourceCode_h
#define AppleSourceCode_h

#include <Security/SecCertificate.h>
#include <CoreFoundation/CFArray.h>
#include <CoreFoundation/CFDictionary.h>
#include <CoreFoundation/CFDate.h>
#include <CoreFoundation/CFError.h>

typedef struct __CFRuntimeBase {
    uintptr_t _cfisa;
    uint8_t _cfinfo[4];
#if __LP64__
    uint32_t _rc;
#endif
} CFRuntimeBase;

struct SecCertificatePath {
    CFRuntimeBase        _base;
    CFIndex                count;
    
    /* Index of next parent source to search for parents. */
    CFIndex                nextParentSource;
    
    /* Index of last certificate in chain who's signature has been verified.
     0 means nothing has been checked.  1 means the leaf has been verified
     against it's issuer, etc. */
    CFIndex                lastVerifiedSigner;
    
    /* Index of first self issued certificate in the chain.  -1 mean there is
     none.  0 means the leaf is self signed.  */
    CFIndex                selfIssued;
    
    /* True iff cert at index selfIssued does in fact self verify. */
    bool                isSelfSigned;
    
    /* True if the root of this path is a trusted anchor.
     FIXME get rid of this since it's a property of the evaluation, not a
     static feature of a certificate path? */
    bool                isAnchored;
    SecCertificateRef    certificates[];
};
typedef struct SecCertificatePath *SecCertificatePathRef;

struct __SecTrust {
    CFRuntimeBase            _base;
    CFArrayRef                _certificates;
    CFArrayRef                _anchors;
    CFTypeRef                _policies;
    CFArrayRef                _responses;
    CFDateRef                _verifyDate;
    SecCertificatePathRef    _chain;
    SecKeyRef                _publicKey;
    CFArrayRef              _details;
    CFDictionaryRef         _info;
    CFArrayRef              _exceptions;
    
    /* Note that a value of kSecTrustResultInvalid (0)
     * indicates the trust must be (re)evaluated; any
     * functions which modify trust parameters in a way
     * that would invalidate the current result must set
     * this value back to kSecTrustResultInvalid.
     */
    SecTrustResultType      _trustResult;
    
    /* If true we don't trust any anchors other than the ones in _anchors. */
    bool                    _anchorsOnly;
    
    /* Master switch to permit or disable network use in policy evaluation */
    int        _networkPolicy;
};


#endif /* AppleSourceCode_h */
