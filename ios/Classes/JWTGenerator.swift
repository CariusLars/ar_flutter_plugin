//
//  JWTGenerator.swift
//  ar_flutter_plugin
//
//  Created by Lars Carius on 08.04.21.
//

import Foundation
import SwiftJWT

class JWTGenerator {
    
    func generateWebToken() -> String? {
        if let path = Bundle.main.path(forResource: "cloudAnchorKey", ofType: "json") {
            do {
              let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
              let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
              if let jsonResult = jsonResult as? Dictionary<String, AnyObject>,
                 let type = jsonResult["type"] as? String,
                 let projectId = jsonResult["project_id"] as? String,
                 let privateKeyId = jsonResult["private_key_id"] as? String,
                 let privateKey = jsonResult["private_key"] as? String,
                 let clientEmail = jsonResult["client_email"] as? String,
                 let clientId = jsonResult["client_id"] as? String,
                 let authUri = jsonResult["auth_uri"] as? String,
                 let tokenUri = jsonResult["token_uri"] as? String,
                 let authProviderX509CertUrl = jsonResult["auth_provider_x509_cert_url"] as? String,
                 let clientX509CertUrl = jsonResult["client_x509_cert_url"] as? String{
                
                    let jwtTokenHeader = Header(typ: type, jku: tokenUri, kid: privateKeyId, x5u: authProviderX509CertUrl, x5c: [clientX509CertUrl])
                    
                    struct JWTTokenClaims: Claims {
                        let iss: String
                        let sub: String
                        let iat: Date
                        let exp: Date
                        let aud: String
                    }
                    let jwtTokenClaims = JWTTokenClaims(iss: clientEmail, sub: clientEmail, iat: Date(), exp: Date(timeIntervalSinceNow: 3600), aud: "https://arcore.googleapis.com/")
                  
                    var jwtToken = JWT(header: jwtTokenHeader, claims: jwtTokenClaims)
                    
                    // Sign Token
                    let jwtSigner = JWTSigner.rs256(privateKey: privateKey.data(using: String.Encoding.ascii)!)
                    
                    let signedJwtToken = try jwtToken.sign(using: jwtSigner)
                    
                    return signedJwtToken
                  
                  }
              } catch {
                   print("Error generating JWT")
              }
        }
        return nil
    }
    
}
