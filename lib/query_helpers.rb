module QueryHelper 
  def self.dropZeros( string )
    digits = self.countZeros(string)
    return string[0, string.length-digits]
  end

  def self.countZeros( string )
    count = 0
    pos = string.length
    while pos > 0
      if string[pos-1] == '0'
        count = count +1
      else
        break
      end
      pos = pos - 1
    end
    return count
  end

  def self.buildSearchParamsFromString(searchString)
    fields = searchString.split("#")
    params = {
      :cpvGroup => fields[0],
      :tender_registration_number => fields[1],
      :tender_status => fields[2],
      :announced_after => fields[3],
      :announced_before => fields[4],
      :min_estimate => fields[5],
      :max_estimate => fields[6],
      :min_num_bids => fields[7],
      :max_num_bids => fields[8],
      :min_num_bidders => fields[9],
      :max_num_bidders => fields[10],
      :risk_indicator => ""
    }
    if fields[11]
      params[:risk_indicator] = fields[11]
    end
    params.each do |key,param|
      if param.length == 1
        params[key] = param.gsub("_","")
      end
    end
    return params
  end


  def self.addParamToQuery(query, param, sql_field, operator,conjunction)
    if param != "" and param != "%%"
      query += " "+conjunction+" "
      query += sql_field +" "+operator+" "+ "'"+param+"'"
    end
    return query
  end
  

 def self.buildTenderSearchQuery(params)
    #all params should already be in string format
    query = ""
    query = self.addParamToQuery(query, params[:tender_registration_number], "tender_registration_number", "LIKE", "")
    query = self.addParamToQuery(query, params[:tender_status], "tender_status", "=", "AND" )
    query = self.addParamToQuery(query, params[:tender_type], "tender_type", "=", "AND" )
    query = self.addParamToQuery(query, params[:announced_after], "tender_announcement_date", ">=" , "AND" )
    query = self.addParamToQuery(query, params[:announced_before], "tender_announcement_date", "<=", "AND" )
    query = self.addParamToQuery(query, params[:min_estimate], "estimated_value", ">=", "AND" )
    query = self.addParamToQuery(query, params[:max_estimate], "estimated_value", "<=", "AND" )
    query = self.addParamToQuery(query, params[:min_num_bids], "num_bids", ">=", "AND" )
    query = self.addParamToQuery(query, params[:max_num_bids], "num_bids", "<=", "AND" )
    query = self.addParamToQuery(query, params[:min_num_bidders], "num_bidders", ">=", "AND" )
    query = self.addParamToQuery(query, params[:max_num_bidders], "num_bidders", "<=" , "AND" )
    query = self.addParamToQuery(query, params[:risk_indicator], "risk_indicators", "LIKE", "AND" )
    query = self.addParamToQuery(query, params[:procurer], "procurer_name", "LIKE", "AND" )
    query = self.addParamToQuery(query, params[:supplier], "supplier_name", "LIKE", "AND" )


    #add cpv codes
    cpvGroup = CpvGroup.where(:id => params[:cpvGroupID]).first
    if not cpvGroup or cpvGroup.id == 1
    else      
      cpvCategories = cpvGroup.tender_cpv_classifiers
      count = 1
      queryAddition = query.length > 0
      cpvCategories.each do |category|
        conjunction = ""
        if queryAddition
          conjunction = " AND ("
        end
        if count > 1
          conjunction = " OR"
        end
        cpvDropped = self.dropZeros(category.cpv_code)
        query = query + conjunction+" cpv_code LIKE '"+cpvDropped+"%'"
        count = count + 1
      end
      if count > 1 and queryAddition
        query = query + " )"
      end
    end

    #add keywords
    if params[:keywords]
      keywords = params[:keywords].split
      count = 0
      queryAddition = query.length > 0
      conjunction = (queryAddition)? " AND (":""
      keywords.each do |word|
        if count > 0 
          conjunction = " OR"
        end
        subString = "'%"+word+"%'" 
        query+= conjunction+" addition_info LIKE "+subString+" OR supplier_name LIKE "+subString+" OR procurer_name LIKE "+subString 
        count+=1
      end
      query+= (queryAddition and count > 0 )? ")":""
    end

    return query
  end
end
