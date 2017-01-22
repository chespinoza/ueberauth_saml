defmodule SAML.KeyInfo do
  import XmlBuilder
  import Record

  defstruct certificate: ""
  defrecord :PrivateKeyInfo, extract(:PrivateKeyInfo, from_lib: "public_key/include/public_key.hrl")
  
  def init(certificate) do
    %SAML.KeyInfo{certificate: certificate}
  end

  def from_file(path) do
    case SAML.Cache.private_key(path) do
      nil -> 
        {:ok, keyfile} = :file.read_file(path)
        [entry] = :public_key.pem_decode(keyfile)
        key = case :public_key.pem_entry_decode(entry) do
          PrivateKeyInfo(privateKey: key_data) -> 
            :public_key.der_decode(:RSAPrivateKey, :erlang.list_to_binary(key_data))
          other -> other
        end
        SAML.Cache.private_key(path, key)
        key
      key ->
        key
    end
  end

  def to_elements(%SAML.KeyInfo{} = desc) do
    element("KeyInfo", %{"xmlns": "http://www.w3.org/2000/09/xmldsig#"}, [
      element("X509Data", %{}, [
        element("X509Certificate", %{}, desc.certificate |> :base64.encode)
      ])
    ])
  end

  def to_xml(%SAML.KeyInfo{} = desc) do
    to_elements(desc) |> generate
  end
end