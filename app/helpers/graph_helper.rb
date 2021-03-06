module GraphHelper
  
  def createTreeGraphStringFromAgreements( agreements )
    cpvTree = []
    done = false
    while not done
      newNodes = [] 
      agreements.each do |key, agreement|
        if key == "99999999"
          next
        end     
        parentKey = getParentCode(key)
        if parentKey and not agreements[parentKey]
          parent = TenderCpvClassifier.where(:cpv_code => parentKey).first
          if parent
            name = parent.description_english or 'na'         
            newNodes.push({ :name => name, :code => parentKey, :children => [] })
          else
            puts "missing parent: "+parentKey
          end
        end
      end
      if newNodes.length == 0
        done = true
      else
        newNodes.each do |node|
          agreements[node[:code]] = node
        end
      end
    end
    
    agreements.each do |key, agreement|
      cpvTree.push( agreement )
    end

    jsonString = ""
    if cpvTree.length > 0
      #lets make a tree out of our CPV codes
      root = { :name => "", :code => "00000000", :children => [] }
      cpvTree.sort! {|x,y| x[:code] <=> y[:code] }
      root = createTree( root, cpvTree )
      root = createUndefinedCategories( root )
      calcParentVal( root )
      jsonString = createJsonString( root, jsonString )
      jsonString.chop!
    end
    return jsonString
  end

  def getParentCode( code )
    digits = countZeros(code)
    parentSuffix = ""
    if digits < 6 
      parentPrefix = code[0, code.length-(digits+1)]
      for i in 0..digits
        parentSuffix += "0"
      end
      return parentPrefix + parentSuffix
    end
    return nil 
  end  

  def createTree( root, list )
    prev = root

    list.each do |node|
      parent = prev
      while not isChild(parent,node)
        parent = parent[:parent]
      end
       
      parent[:children].push(node)
      node[:parent] = parent
      prev = node
    end
    return root
  end

  def countZeros( string )
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

  def isChild(parent, node)
    if parent[:code] == "00000000" 
      return true
    elsif parent[:code] == node[:code]
      return false
    else
      nodeDigits = countZeros(node[:code])
      #6 zeros or more means this is a primary grouping
      if nodeDigits >= 6
        return false
      end
      digits = countZeros(parent[:code])
      parentString = parent[:code]
      subParent = parentString[0, parentString.length-digits]
      codeString = node[:code]
      subCode = codeString[0, codeString.length-digits]
      return subParent == subCode
    end
  end


  #make parent values the sum of all child values
  def calcParentVal( root )
    if root[:children].length == 0
      return root[:value]
    else
      root[:children].each do |child|
        root[:value] += calcParentVal( child )
      end
      return root[:value]
    end
  end

  #pass parent category values down into new uncategorised childs
  def createUndefinedCategories( root )
    if not root[:value]
      root[:value] = 0
    end

    if root[:children].length > 0
      uncategorised = root[:value]
      if uncategorised > 0
        root[:children].push( { :name => "Miscellaneous", :value => uncategorised, :code => root[:code], :children => [] } )
      end
      root[:value] = 0
      root[:children].each do |child|
        createUndefinedCategories(child)
      end
    end
    return root
  end

  def createJsonString( root, jsonString )
    jsonString +="{"
    jsonString += '"name": ' + '"'+root[:name]+'"'+','
    jsonString += '"value": ' + root[:value].to_s+','
    jsonString += '"code": ' + root[:code].to_s+','
 
    if root[:children].length > 0
      jsonString += '"children": ['
      root[:children].each do |child|
        jsonString += createJsonString( child, "" )
      end
      jsonString += ']'
    end
    jsonString += "},"
    return jsonString
  end
end
