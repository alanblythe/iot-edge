/*
 *  Copyright (c) Microsoft. All rights reserved.
 *  Licensed under the MIT license. See LICENSE file in the project root for full license information.
 */

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.math.BigInteger;
import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.Key;
import java.security.KeyFactory;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.NoSuchAlgorithmException;
import java.security.PrivateKey;
import java.security.SecureRandom;
import java.security.cert.Certificate;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.security.interfaces.RSAPrivateKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.RSAPrivateCrtKeySpec;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Collection;

import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;

import sun.security.util.DerInputStream;
import sun.security.util.DerValue;

/**
 * Helper class that demonstrates how to build an SSLContext for x509 authentication from your public and private certificates,
 * or how to build an SSLContext for SAS authentication from the default IoT Hub public certificates
 */
public class SSLContextBuilder
{
    private static final String SSL_CONTEXT_INSTANCE = "TLSv1.2";
    private static final String CERTIFICATE_TYPE = "X.509";
    private static final String CERTIFICATE_ALIAS = "cert-alias";
    private static final String PRIVATE_KEY_ALIAS = "key-alias";

    /**
     * Create an SSLContext instance with the provided public certificate and private key that also trusts the public
     * certificates loaded in your device's trusted root certification authorities certificate store.
     * @param publicKeyCertificate the public key to use for x509 authentication. Does not need to include the
     *                                   Iot Hub trusted certificate as it will be added automatically as long as it is
     *                                   in your device's trusted root certification authorities certificate store.
     * @param privateKey The private key to use for x509 authentication
     * @return The created SSLContext that uses the provided public key and private key
     * @throws GeneralSecurityException If the certificate creation fails, or if the SSLContext creation using those certificates fails.
     * @throws IOException If the certificates cannot be read.
     */
    public static SSLContext buildSSLContext(X509Certificate publicKeyCertificate, PrivateKey privateKey) throws GeneralSecurityException, IOException
    {
        char[] temporaryPassword = generateTemporaryPassword();

        KeyStore keystore = KeyStore.getInstance(KeyStore.getDefaultType());
        keystore.load(null);
        keystore.setCertificateEntry(CERTIFICATE_ALIAS, publicKeyCertificate);
        keystore.setKeyEntry(PRIVATE_KEY_ALIAS, privateKey, temporaryPassword, new Certificate[] {publicKeyCertificate});

        KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
        kmf.init(keystore, temporaryPassword);

        SSLContext sslContext = SSLContext.getInstance(SSL_CONTEXT_INSTANCE);

        // By leaving the TrustManager array null, the SSLContext will trust the certificates stored on your device's
        // trusted root certification authorities certificate store.
        //
        // This must include the Baltimore CyberTrust Root public certificate: https://baltimore-cybertrust-root.chain-demos.digicert.com/info/index.html
        // and eventually it will need to include the DigiCert Global Root G2 public certificate: https://global-root-g2.chain-demos.digicert.com/info/index.html
        sslContext.init(kmf.getKeyManagers(), null, new SecureRandom());

        return sslContext;
    }

    /**
     * Create an SSLContext instance with the provided public certificate and private key that also trusts the public
     * certificates loaded in your device's trusted root certification authorities certificate store.
     * @param publicKeyCertificateString the public key to use for x509 authentication. Does not need to include the
     *                                   Iot Hub trusted certificate as it will be added automatically as long as it is
     *                                   in your device's trusted root certification authorities certificate store.
     * @param privateKeyString The private key to use for x509 authentication
     * @return The created SSLContext that uses the provided public key and private key
     * @throws GeneralSecurityException If the certificate creation fails, or if the SSLContext creation using those certificates fails.
     * @throws IOException If the certificates cannot be read.
     */
    public static SSLContext buildSSLContext(String publicKeyCertificateString, String privateKeyString) throws GeneralSecurityException, IOException
    {
        Key privateKey = pemFileLoadPrivateKeyPkcs1OrPkcs8Encoded(privateKeyString);
        Certificate[] publicKeyCertificates = parsePublicCertificateString(publicKeyCertificateString);

        char[] temporaryPassword = generateTemporaryPassword();

        KeyStore keystore = KeyStore.getInstance(KeyStore.getDefaultType());
        keystore.load(null);
        keystore.setCertificateEntry(CERTIFICATE_ALIAS, publicKeyCertificates[0]);
        keystore.setKeyEntry(PRIVATE_KEY_ALIAS, privateKey, temporaryPassword, publicKeyCertificates);

        KeyManagerFactory kmf = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
        kmf.init(keystore, temporaryPassword);

        SSLContext sslContext = SSLContext.getInstance(SSL_CONTEXT_INSTANCE);

        // By leaving the TrustManager array null, the SSLContext will trust the certificates stored on your device's
        // trusted root certification authorities certificate store.
        //
        // This must include the Baltimore CyberTrust Root public certificate: https://baltimore-cybertrust-root.chain-demos.digicert.com/info/index.html
        // and eventually it will need to include the DigiCert Global Root G2 public certificate: https://global-root-g2.chain-demos.digicert.com/info/index.html
        sslContext.init(kmf.getKeyManagers(), null, new SecureRandom());

        return sslContext;
    }

    /**
     * Build the default SSLContext. Trusts the certificates stored in your device's trusted root certification
     * authorities certificate store.
     * @return the default SSLContext
     * @throws NoSuchAlgorithmException If the SSLContext cannot be created because of a missing algorithm.
     * @throws KeyManagementException If the SSLContext cannot be initiated.
     */
    public static SSLContext buildSSLContext() throws NoSuchAlgorithmException, KeyManagementException
    {
        SSLContext sslContext = SSLContext.getInstance(SSL_CONTEXT_INSTANCE);

        // By leaving the KeyManager array null, the SSLContext will not present any private keys during the TLS
        // handshake. This means that the connection will need to be authenticated via a SAS token or similar mechanism.
        //
        // By leaving the TrustManager array null, the SSLContext will trust the certificates stored on your device's
        // trusted root certification authorities certificate store.
        //
        // This must include the Baltimore CyberTrust Root public certificate: https://baltimore-cybertrust-root.chain-demos.digicert.com/info/index.html
        // and eventually it will need to include the DigiCert Global Root G2 public certificate: https://global-root-g2.chain-demos.digicert.com/info/index.html
        sslContext.init(null, null, new SecureRandom());

        return sslContext;
    }
    
    private static RSAPrivateKey pemFileLoadPrivateKeyPkcs1OrPkcs8Encoded(String privateKeyString) throws GeneralSecurityException, IOException {
        // PKCS#8 format
        final String PEM_PRIVATE_START = "-----BEGIN PRIVATE KEY-----";
        final String PEM_PRIVATE_END = "-----END PRIVATE KEY-----";

        // PKCS#1 format
        final String PEM_RSA_PRIVATE_START = "-----BEGIN RSA PRIVATE KEY-----";
        final String PEM_RSA_PRIVATE_END = "-----END RSA PRIVATE KEY-----";

        String privateKeyPem = privateKeyString;

        if (privateKeyPem.indexOf(PEM_PRIVATE_START) != -1) { // PKCS#8 format
            privateKeyPem = privateKeyPem.replace(PEM_PRIVATE_START, "").replace(PEM_PRIVATE_END, "");
            privateKeyPem = privateKeyPem.replaceAll("\\s", "");

            byte[] pkcs8EncodedKey = Base64.getDecoder().decode(privateKeyPem);

            KeyFactory factory = KeyFactory.getInstance("RSA");
            return (RSAPrivateKey)factory.generatePrivate(new PKCS8EncodedKeySpec(pkcs8EncodedKey));

        } else if (privateKeyPem.indexOf(PEM_RSA_PRIVATE_START) != -1) {  // PKCS#1 format

            privateKeyPem = privateKeyPem.replace(PEM_RSA_PRIVATE_START, "").replace(PEM_RSA_PRIVATE_END, "");
            privateKeyPem = privateKeyPem.replaceAll("\\s", "");

            DerInputStream derReader = new DerInputStream(Base64.getDecoder().decode(privateKeyPem));

            DerValue[] seq = derReader.getSequence(0);

            if (seq.length < 9) {
                throw new GeneralSecurityException("Could not parse a PKCS1 private key.");
            }

            // skip version seq[0];
            BigInteger modulus = seq[1].getBigInteger();
            BigInteger publicExp = seq[2].getBigInteger();
            BigInteger privateExp = seq[3].getBigInteger();
            BigInteger prime1 = seq[4].getBigInteger();
            BigInteger prime2 = seq[5].getBigInteger();
            BigInteger exp1 = seq[6].getBigInteger();
            BigInteger exp2 = seq[7].getBigInteger();
            BigInteger crtCoef = seq[8].getBigInteger();

            RSAPrivateCrtKeySpec keySpec = new RSAPrivateCrtKeySpec(modulus, publicExp, privateExp, prime1, prime2, exp1, exp2, crtCoef);

            KeyFactory factory = KeyFactory.getInstance("RSA");

            return (RSAPrivateKey)factory.generatePrivate(keySpec);
        }

        throw new GeneralSecurityException("Not supported format of a private key");
    }

    private static X509Certificate[] parsePublicCertificateString(String pemString) throws GeneralSecurityException, IOException
    {
        if (pemString == null || pemString.isEmpty())
        {
            throw new IllegalArgumentException("Public key certificate cannot be null or empty");
        }

        try (InputStream pemInputStream = new ByteArrayInputStream(pemString.getBytes(StandardCharsets.UTF_8)))
        {
            CertificateFactory cf = CertificateFactory.getInstance(CERTIFICATE_TYPE);
            Collection<X509Certificate> collection = new ArrayList<>();
            X509Certificate x509Cert;

            while (pemInputStream.available() > 0)
            {
                x509Cert = (X509Certificate) cf.generateCertificate(pemInputStream);
                collection.add(x509Cert);
            }

            return collection.toArray(new X509Certificate[0]);
        }
    }

    private static char[] generateTemporaryPassword()
    {
        char[] randomChars = new char[256];
        SecureRandom secureRandom = new SecureRandom();

        for (int i = 0; i < 256; i++)
        {
            // character will be between 97 and 122 on the ASCII table. This forces it to be a lower case character.
            // that ensures that the password, as a whole, is alphanumeric
            randomChars[i] = (char) (97 + secureRandom.nextInt(26));
        }

        return randomChars;
    }
}