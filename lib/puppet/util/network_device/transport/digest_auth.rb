class Net::HTTP::DigestAuth
  #binding.pry
  md5 = Digest::MD5.new
  x = (Time.now.to_i + rand(65535))
  md5.update x.to_s
  CNONCE = md5.hexdigest #Digest::MD5.new("%x" % (Time.now.to_i + rand(65535))).hexdigest

  def initialize ignored = :ignored
    @@nonce_count = -1
  end

  def auth_header(user, password, response, method, path)
    @@nonce_count += 1
    puts response.header['www-authenticate']
    puts path
    puts method

    response.header['www-authenticate'] =~ /^(\w+) (.*)/

    params = {}
    $2.gsub(/(\w[a-zA-Z0-9_ ]+)=[\\"](.*?)[\\"][,$]/) { params[$1] = $2 }
    puts params

    a_1 = "#{user}:#{params['realm']}:#{password}"
    hexdata_1 = Digest::MD5.new
    hexdata_1.update a_1.to_s
    a_2 = "#{method}:#{path}"
    hexdata_2 = Digest::MD5.new
    hexdata_2.update a_2.to_s
    request_digest = ''
    request_digest << hexdata_1.hexdigest
    request_digest << ':' << params['nonce']
    request_digest << ':' << ('%08x' % @@nonce_count)
    request_digest << ':' << CNONCE
    request_digest << ':' << params['qop']
    request_digest << ':' << hexdata_2.hexdigest
    puts request_digest
    hexdata_req = Digest::MD5.new
    hexdata_req.update request_digest.to_s

    header = []
    header << "username=\"#{user}\""
    header << "realm=\"#{params['realm']}\""

    header << "qop=#{params['qop']}"

    header << "algorithm=\"MD5\""
    header << "uri=\"#{path}\""
    header << "nonce=\"#{params['nonce']}\""
    header << "nc=#{'%08x' % @@nonce_count}"
    header << "cnonce=\"#{CNONCE}\""
    header << "response=\"#{hexdata_req.hexdigest}\""
    puts header

    "Digest #{header.join(', ')}"
  end
end