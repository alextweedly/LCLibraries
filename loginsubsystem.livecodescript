script "loginsubsystem"
local sALoggedInUser

function login_User
   return firstOf(sALoggedInUser["username"], sALoggedInUser["email"])
end login_User

function login_Email
   return sALoggedInUser["email"]
end login_Email

function login_Token
   return sALoggedInUser["token"]
end login_Token

function login_auth pUser, pEMail, pPassword
   local tDataA, tResultA
   put pEmail into tDataA["email"]
   put pPassword into tDataA["password"]
   put remoteDatabaseOther("", "users", "login", tDataA) into tResultA
   if tResultA["token"] is not empty then -- successfully logged in
      put tResultA into sALoggedInUser
      return sALoggedInUser["token"]
   end if
   return empty
end login_auth

function login_authStatus
   return sALoggedInUser
end login_authStatus

on login_logout
   local tDataA, tResultA
   put sALoggedInUser["token"] into tDataA["token"]
   put remoteDatabaseOther("", "users", "logout", tDataA) into tResultA
   put empty into sALoggedInUser
   if tResultA["token"] is not empty then 
      return sALoggedInUser["token"]
   end if
   return empty
end login_logout

function login_register pA
   local tResultA
   put remoteDatabaseOther("", "users", "register", pA) into tResultA
   return tResultA
end login_register

function login_modify pA
   local tResult
   dbWhere "username", sALoggedInUser["username"]
   --   put remoteDatabaseOther("", "users", "register", pA) into tResultA
   put dbUpdate("users", pA) into tResult
   put login_userinfo() into sALoggedInUser
   return tResult
end login_modify

function login_userinfo
   local tAResult
   dbWhere "username", sALoggedInUser["username"]
   put dbGetOne("users") into tAResult
   put tAResult into sALoggedInUser
   return tAResult
end login_userinfo

