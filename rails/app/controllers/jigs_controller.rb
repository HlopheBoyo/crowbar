# Copyright 2013, Dell
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.1
#
#
class JigsController < ApplicationController

  def match
    attrs = Jig.attribute_names.map{|a|a.to_sym}
    objs = Jig.where(params.permit(attrs))
    respond_to do |format|
      format.html {}
      format.json { render api_index Jig, objs }
    end
  end
  
  def index
    respond_to do |format|
      format.html { @jigs = Jig.order('"order"') } # show.html.erb
      format.json { render api_index Jig, Jig.all }
    end
  end

  def show
    respond_to do |format|
      @jig = Jig.find_key params[:id]
      format.html {  }
      format.json { render api_show @jig, "jig" }
    end
  end

  def create
    render api_not_supported("post", "jigs")
  end

  def update
    @jig = Jig.find_key(params[:id])
    @jig.update_attributes!(params.permit(:description,:active,:server,:client_name,:key))
    render api_show @jig
  end

  def destroy
    render api_not_supported("post", "jigs")
  end

end
